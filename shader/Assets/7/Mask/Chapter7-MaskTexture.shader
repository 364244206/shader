
// 遮罩纹理：根据纹理的rgba通道，达到改变主体颜色的显示效果
// 本例中，通过获取遮罩图的r通道(翅膀效果)，其他位置为黑色值为0，则过滤掉非翅膀的位置，则高光会出现翅膀的光照效果
// 也可以用黑色背景的三基色图，来展示rgb不同通道的过滤效果
Shader "Unity Shaders Book/Chapter 7/Mask Texture" {
	Properties {
		_Color("Color Tint", Color) = (1, 1, 1, 1)
		_MainTex("Main Tex", 2D) = "white" {}

		_BumpMap("Normal Map", 2D) = "bump" {}
		_BumpScale("Bump Scale", Float) = 1.0

		_SpecularMask("Specular Mask", 2D) = "white" {}
		_SpecularScale("Specular Scale", Float) = 1.0

		_Specular("Specular", Color) = (1, 1, 1, 1)
		_Gloss("Gloss", Range(8.0, 256)) = 20
	}
	SubShader {
		Pass { 
			Tags { "LightMode"="ForwardBase" }
		
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;

			sampler2D _BumpMap;
			float _BumpScale;

			sampler2D _SpecularMask;
			float _SpecularScale;

			fixed4 _Specular;
			float _Gloss;
			
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 lightDir : TEXCOORD1;
				float3 viewDir : TEXCOORD2;
			};
			
			v2f vert(a2v v) {
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;

				// 1.模型空间中的三个单位坐标轴TBN，按照列摆放的变换矩阵M，可以从切线空间 变换到 模型空间
				// 2.而矩阵M的逆矩阵，可以从模型空间 变换到 切线空间
				// 3.正交矩阵的逆矩阵等于转置矩阵
				// 4.则矩阵M的转置矩阵(按照行摆放)，可以从模型空间 变换到 切线空间
				float3 binormal = cross(normalize(v.normal), normalize(v.tangent.xyz)) * v.tangent.w;
				float3x3 rotation = float3x3(v.tangent.xyz, binormal, v.normal);

				o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
				o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;

				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				fixed3 tangentLightDir = normalize(i.lightDir);
				fixed3 tangentViewDir = normalize(i.viewDir);

				// 对法线纹理采样，然后解压缩从像素值 转换为 法线方向
				fixed3 tangentNormal = UnpackNormal(tex2D(_BumpMap, i.uv));
				tangentNormal.xy *= _BumpScale;
				tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

				// 材质本身颜色
				fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
				// 环境光
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				// 慢反射 灯光色*材质色*dot
				fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));
				// 半角方向
				fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);
				// 获取遮罩的值
				fixed specularMask = tex2D(_SpecularMask, i.uv).g * _SpecularScale;
				// blinn高光
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal, halfDir)), _Gloss);
				// 叠加遮罩
				specular = specular * specularMask;
				return fixed4(ambient + diffuse + specular, 1.0);
			}
			
			ENDCG
		}
	} 
	FallBack "Specular"
}
