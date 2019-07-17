// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Unity Shaders Book/Chapter 6/Specular Vertex-Level" {
	Properties {
		_Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
		_Specular ("Specular", Color) = (1, 1, 1, 1)   
		_Gloss ("Gloss", Range(8.0, 256)) = 20         
	}
	SubShader {
		Pass { 
			Tags { "LightMode"="ForwardBase" }
			
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"
			
			fixed4 _Diffuse;   
			fixed4 _Specular;   // 高光反射颜色
			float _Gloss;       // 光泽强度
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				fixed3 color : COLOR;
			};
			
			v2f vert(a2v v) {
				v2f o;
				// 将模型空间中顶点坐标转换到投影空间
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				// 获取环境光
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				// 1.我们知道法线可以用模型空间到世界空间的逆转置矩阵来变换
				// 2.先获取模型到世界的逆矩阵unity_WorldToObject
				// 3.然后通过变换mul的顺序，来得到和转置矩阵相同的矩阵乘法
				fixed3 worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
				// 光照方向
				fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				
				// 计算漫反射
				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLightDir));
				// 获取反射向量
				fixed3 reflectDir = normalize(reflect(-worldLightDir, worldNormal));
	 			// 获取摄像机方向
				fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld, v.vertex).xyz);

				// 计算高光颜色
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(reflectDir, viewDir)), _Gloss);

				o.color = ambient + diffuse + specular;
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				return fixed4(i.color, 1.0);
			}
			
			ENDCG
		}
	} 
	FallBack "Specular"
}
