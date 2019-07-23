Shader "swan/ShadowMap/ShadowMapNormal"
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

			struct v2f {
				float4 pos:SV_POSITION;
				float2 uv:TEXCOORD0;
	
				float4 proj : TEXCOORD1;
				float2 depth : TEXCOORD2;
			};

			float4x4 _WorldToProjectionMatrix; //【世界空间】变换【摄像机投影空间】矩阵
			sampler2D _DepthTexture;

			v2f vert(appdata_full v)
			{
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

				// 深度信息
				// o.pos.z要除以分量w才是最终的深度，但是因为顶点到片元有一个差值的过程
				// 投影空间中不是线性的，除以w后坐标会不准确，所以在片元中再除以w结果才是正确的
				o.depth = o.pos.zw;
				// 【模型空间】变换【世界空间】矩阵 右乘 【世界空间】变换【摄像机投影空间】矩阵
				float4x4 _ObjectToProjectionMatrix = mul(_WorldToProjectionMatrix, unity_ObjectToWorld);
				// 将【模型顶点】变换到灯光的【投影空间】中
				o.proj = mul(_ObjectToProjectionMatrix, v.vertex);
				// 顶点从MVP变换后的立方体中值域是【-1,1】，但是深度图值域是【0,1】，需要映射
				// 为了效率，可以将映射过程构建为矩阵放到C#端编写
				o.proj = o.proj * 0.5f + 0.5f;
				return o;
			}

			fixed4 frag(v2f v) : COLOR
			{
				fixed4 col = tex2D(_MainTex, v.uv);
				// 除以w分量，获取屏幕空间中像素的深度值
				float depth = v.depth.x / v.depth.y;
				// 透视投影和正交投影在经过齐次除法后，w分量其实都为1了
				// proj其实是内置了齐次除法，除以了分量w
				fixed4 dcol = tex2Dproj(_DepthTexture, v.proj);
				// 从深度图中取出深度值
				float shadowDepth = DecodeFloatRGBA(dcol);
				float shadowScale = 1;
				if (depth > shadowDepth)
				{
					shadowScale = 0.4f;
				}
				return col * shadowScale;
			}
			ENDCG
		}
	}
}