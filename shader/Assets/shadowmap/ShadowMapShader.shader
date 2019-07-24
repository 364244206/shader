Shader "ShadowMapShader"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
	}

		SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			sampler2D _MainTex;
			half4 _MainTex_ST;

			float4x4 _WorldToProjectionMatrix; //【世界空间】变换【摄像机投影空间】矩阵
			sampler2D _DepthTexture;
			int _TexelWidth;
			int _TexelHight;

			struct appdata
			{
				half4 vertex :		POSITION;
				half2 texcoord :	TEXCOORD0;

				half3 normal :		NORMAL;
			};

			struct v2f {
				half4 pos:		SV_POSITION;
				half2 uv:		TEXCOORD0;
				half4 proj :	TEXCOORD1;

				half3 normal :  TEXCOORD2;
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

				half4 worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.proj = mul(_WorldToProjectionMatrix, worldPos);
				o.normal = UnityObjectToWorldNormal(v.normal);

				return o;
			}

			// 问题2:阴影锯齿问题
			// PCF滤波(百分比渐进滤波percentage-closer filtering)
			// 对某个位置相邻的N个片元也进行采样，叠加阴影值得到平均值
			// 1 1 1 1 1
			// 1 1 1 1 1
			// 1 1 0 1 1
			// 1 1 1 1 1
			// 1 1 1 1 1
			float PercentCloaerFilter(float2 texSize, float2 xy, float sceneDepth, float bias, int filterSize)
			{
				float shadow = 0.0;
				// 映射到【0,1】时，一个像素的大小
				float2 unitSize = 1 / texSize;
				for (int x = -filterSize; x <= filterSize; ++x)
				{
					for (int y = -filterSize; y <= filterSize; ++y)
					{
						// 获取偏移uv坐标
						float2 uv_offset = float2(x, y) * unitSize;
						// 通过当前像素uv坐标位置，获取深度图颜色, 通过深度图颜色，获取深度值
						float depth = DecodeFloatRGBA(tex2D(_DepthTexture, xy + uv_offset));
						// 通过【当前片元的深度值】与【当前片元坐标对应深度图的深度值】进行比较
						// 将当前片元是阴影色叠加
						shadow += (sceneDepth - bias > depth ? 1.0 : 0.0);
					}
				}
				// 得到当前片元阴影平均色
				float total = (filterSize * 2 + 1) * (filterSize * 2 + 1);
				shadow /= total;
				return shadow;
			}

			fixed4 frag(v2f v) : COLOR
			{
				fixed4 col = tex2D(_MainTex, v.uv);
			// /w后，顶点从MVP变换后的立方体中值域是【-1,1】
			v.proj.xyz = v.proj.xyz / v.proj.w;
			// 但是要用这个变化过的坐标值来查找深度图中的深度，就得做值域转换
			// 这个过程可以放到C#端，减少计算频率
			v.proj.xyz = v.proj.xyz * 0.5 + 0.5;


			// 问题1:斜波深度偏差问题
			// slope scale based depth bias。基于坡度比例的深度偏移
			// 深度图的分辨率有限，那么片元在获取深度信息时，会出现多个片元获取同一个深度信息
			// 而灯光在绘制深度图时是有一定角度，这就导致某些片元间隔的出现一部分深度比深度图大，一部分深度比深度图小
			// 此时抬高地面就可以，或者将深度图的深度信息增大一点点，这个距离就是shadow bias
			// 这个值怎么确定呢，太大太小都不行，此时根据前人的经验总结，根据光源方向和法线方向的夹角确定
			// 灯光方向和法线一样时，dot为1，比如光线无角度直接照射地面，那么此时取最小的0.005
			fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
			fixed3 worldNormalDir = v.normal;
			half bias = max(0.05 * (1.0 - dot(worldNormalDir, worldLightDir)), 0.005);
			// PCF滤波
			float shadowCol = PercentCloaerFilter(float2(_TexelWidth, _TexelHight), v.proj.xy, v.proj.z, bias, 2);

			// 问题3:超出深度图的区域
			// 解决摄像机投影空间为黑色的问题
			// NDC空间下是-1到1，转到屏幕空间时深度为0到1，大于1的不处理阴影
			// 只是不知道为什么是摄像机背后方向的地面为黑色
			if (v.proj.z > 1.0f)
			{
				shadowCol = 0.0f;
			}
			return col * (1 - shadowCol);
		}
		ENDCG
	}
	}
}