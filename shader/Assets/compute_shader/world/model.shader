// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "model" {
	Properties{
	
			_MainTex("Base", 2D) = "white"{}
	}
		SubShader{
			Pass {
					Tags {"Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent"}


					// 这种情况，当此模型的网格交叉时，会出现错误的半透明效果
				//ZWrite Off           // 关闭深度写入
				Blend SrcAlpha OneMinusSrcAlpha	// 源RGB*源A + 背景RGB*(1-源A)

				CGPROGRAM

				#pragma vertex vert
				#pragma fragment frag

				#include "Lighting.cginc"

				sampler2D _MainTex;
				float4 _MainTex_ST;

				sampler2D _CameraDepthTexture; // 系统保存的场景深度

				sampler2D _tex1;
				uniform float4 _pos1;        // 玩家位置
				uniform float4 _camPos1;        // 摄像机位置
				uniform float4 _worldToUv1;

				struct a2v {
					float4 vertex : POSITION;
					float4 texcoord : TEXCOORD0;
				};

				struct v2f {
					float4 position :POSITION;
					float2 uv :TEXCOORD0;
					float4 wPos:TEXCOORD1;
				};

				v2f vert(a2v v) {
					v2f o;
					// 将模型空间中顶点坐标转换到投影空间
					o.position = mul(UNITY_MATRIX_MVP, v.vertex);
					o.uv = v.texcoord.xy;
					o.wPos = mul(unity_ObjectToWorld, v.vertex);
					return o;
				}

				fixed4 frag(v2f i) : COLOR{

					half4 original = tex2D(_MainTex, i.uv);
					float3 pos =  i.wPos;

					// 位置转到tex的中间
					//float center = 128 * 0.5f;
					//pos += float3(center, 0, center);
					half4 col = original;
					if (pos.y > 0.0)
					{
						pos -= _pos1;
						// 将世界坐标的X，Z轴转换为值域为[0-1]的值，用于映射到屏幕空间
						float2 uv = pos.xz * _worldToUv1;
						// 刚进入的和当前可见的纹理融合
						half4 fog = tex2D(_tex1, uv);

						// 屏幕色X黑色的叠加色 与 屏幕色 的插值
						//col = lerp(original * half4(0, 0, 0, 1.0), original, 1 - fog.r);
						// 可以叠加，可以镂空
						if (fog.r >= 1)
						{
							col = fixed4(0, 0, 0, 0);
						}
					}
					return col;
				}

				ENDCG
			}
		}
		FallBack "Transparent/VertexLit"
}
