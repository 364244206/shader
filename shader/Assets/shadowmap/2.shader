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

			#pragma multi_compile_fog

			#include "UnityCG.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;


			// sampler2D unity_Lightmap;//若开启光照贴图，系统默认填值
			// float4 unity_LightmapST;//与上unity_Lightmap同理

			struct v2f {
				float4 pos:SV_POSITION;
				float2 uv:TEXCOORD0;
				float2 uv2:TEXCOORD1;
				UNITY_FOG_COORDS(2)
				float4 proj : TEXCOORD3;
				float2 depth : TEXCOORD4;
			};


			float4x4 lijia_ProjectionMatrix;
			sampler2D lijia_DepthTexture;

			v2f vert(appdata_full v)
			{
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);

				//动态阴影
				o.depth = o.pos.zw;
				lijia_ProjectionMatrix = mul(lijia_ProjectionMatrix, unity_ObjectToWorld);
				o.proj = mul(lijia_ProjectionMatrix, v.vertex);
				//--------------------------------------------------
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uv2 = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
				UNITY_TRANSFER_FOG(o, o.pos);

				return o;
			}

			fixed4 frag(v2f v) : COLOR
			{
				//解密光照贴图计算公式
				float3 lightmapColor = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap,v.uv2));
				fixed4 col = tex2D(_MainTex, v.uv);

				//col.rgb *= lightmapColor;

				UNITY_APPLY_FOG(v.fogCoord, col);

				float depth = v.depth.x / v.depth.y;
				fixed4 dcol = tex2Dproj(lijia_DepthTexture, v.proj);
				float d = DecodeFloatRGBA(dcol);
				float shadowScale = 1;
				if (depth > d)
				{
					shadowScale = 0.55;
				}
				return col * shadowScale;
			}
			ENDCG
		}
	}
}