// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// 高光模型分phong模型和blinn模型
Shader "Unity Shaders Book/Chapter 6/Specular Pixel-Level" {
	Properties{
		_Diffuse("Diffuse", Color) = (1, 1, 1, 1)
		_Specular("Specular", Color) = (1, 1, 1, 1)
		_Gloss("Gloss", Range(8.0, 256)) = 20
	}
		SubShader{
			Pass {
				Tags { "LightMode" = "ForwardBase" }

				CGPROGRAM

				#pragma vertex vert
				#pragma fragment frag

				#include "Lighting.cginc"

				fixed4 _Diffuse;
				fixed4 _Specular;   // 高光反射颜色
				float _Gloss;       // 光泽强度 反光强度 控制亮点大小

				struct a2v {
					float4 vertex : POSITION;
					float3 normal : NORMAL;
				};

				struct v2f {
					float4 pos : SV_POSITION;
					fixed3 worldNormal : NORMAL;
					fixed3 worldPos : TEXCOORD1;
				};

				v2f vert(a2v v) {
					v2f o;
					// 将模型空间中顶点坐标转换到投影空间
					o.pos = mul(UNITY_MATRIX_MVP, v.vertex);

					o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
					o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
					return o;
				}

				fixed4 frag(v2f i) : SV_Target {
					// 环境光
					fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT;
					fixed3 worldNormal = normalize(i.worldNormal);
					fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

					// 漫反射
					fixed3 diffuse = _LightColor0.rgb * _Diffuse * saturate(dot(worldLightDir, worldNormal));

					// 摄像机方向
					fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);

					//// phong模型：摄像机方向和反射方向
					//// 反射光方向 
					//fixed3 reflectDir = normalize(reflect(-worldLightDir, worldNormal));
					//// 高光颜色
					//fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(reflectDir ,viewDir)), _Gloss);

					// binn模型：法线和半角方向
					// 半角向量 （摄像机和光源距离很远时，blinn快于phong）
					fixed3 halfDir = normalize(worldLightDir + viewDir);
					// 高光颜色
					fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(worldNormal, halfDir)), _Gloss);

					return fixed4(ambient + diffuse + specular, 1.0);
				}

				ENDCG
			}
		}
		FallBack "Specular"
}
