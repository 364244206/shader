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
			float4 _MainTex_ST;

			struct appdata
			{
				float4 vertex :		POSITION;
				float2 texcoord :	TEXCOORD0;
			};

			struct v2f {
				float4 pos:		SV_POSITION;
				float2 uv:		TEXCOORD0;
				float4 proj :	TEXCOORD1;
			};

			float4x4 _WorldToProjectionMatrix; //【世界空间】变换【摄像机投影空间】矩阵
			sampler2D _DepthTexture;

			v2f vert(appdata v)
			{
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

				float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.proj = mul(_WorldToProjectionMatrix, worldPos);
				return o;
			}

			fixed4 frag(v2f v) : COLOR
			{
				fixed4 col = tex2D(_MainTex, v.uv);
				// /w后，顶点从MVP变换后的立方体中值域是【-1,1】
				v.proj.xyz = v.proj.xyz / v.proj.w;
				// 但是要用这个变化过的坐标值来查找深度图中的深度，就得做值域转换
				// 这个过程可以放到C#端，减少计算频率
				v.proj.xyz = v.proj.xyz * 0.5 + 0.5;
				// 通过当前像素坐标位置，获取深度图颜色
				fixed4 depthCol = tex2D(_DepthTexture, v.proj.xy);
				// 通过深度图颜色，获取深度值
				float shadowDepth = DecodeFloatRGBA(depthCol);
				// 通过【当前片元的深度值】与【当前片元坐标对应深度图的深度值】进行比较
				float shadowScale = 1;
				if (v.proj.z > shadowDepth)
				{
					shadowScale = 0.4f;
				}
				return col * shadowScale;
			}
			ENDCG
		}
	}
}