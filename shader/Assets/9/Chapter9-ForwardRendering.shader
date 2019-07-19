// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'
// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// 此例子，学习前向渲染中基本的平行光照，叠加点光源灯灯

// 灯光必须开启RenderMode 为auto或者important，
// 并且在edit-projectSetting-quality-pixelLightCount中设置像素光照灯数量,默认4个
// 渲染顺序根据，灯光强度，距离来执行，可以通过帧调试器来查看
Shader "Unity Shaders Book/Chapter 9/Forward Rendering" {
	Properties {
		_Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
		_Specular ("Specular", Color) = (1, 1, 1, 1)
		_Gloss ("Gloss", Range(8.0, 256)) = 20
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		
		Pass {
			// LightMode"="ForwardBase" 支持环境光和平行光
			Tags { "LightMode"="ForwardBase" }
		
			CGPROGRAM
			
			// 此指令可以保证使用光照衰减等光照变量被正确赋值，不可缺少
			#pragma multi_compile_fwdbase	
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"
			
			fixed4 _Diffuse;
			fixed4 _Specular;
			float _Gloss;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
			};
			
			v2f vert(a2v v) {
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				
				return o;
			}
			
			// _WorldSpaceLightPos0得到平行光方向，位置是无意义的
			// _LightColor0得到平行光的颜色强度 _LightColor0是颜色和强度相乘的结果
			// 平行光没有衰减，所以为1
			fixed4 frag(v2f i) : SV_Target {
				fixed3 worldNormal = normalize(i.worldNormal);

				fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				// 环境光只在base中计算一次即可
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				
			 	fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));

			 	fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
			 	fixed3 halfDir = normalize(worldLightDir + viewDir);
			 	fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

				fixed atten = 1.0;
				
				return fixed4(ambient + (diffuse + specular) * atten, 1.0);
			}
			
			ENDCG
		}
	
		// 他们的顶点代码是一样的，但是add中不需要环境光，自发光，逐顶点光照，SH光照部分
		// 对应光照颜色强度，还是使用_LightColor0，其他的则根据光源类型做不同处理
		Pass {
			// Pass for other pixel lights
			Tags { "LightMode"="ForwardAdd" }
			// 混合之前的光照值，如果不混合，则只会显示最后一个光照颜色,也可以用Blend SrcAlpha One
			Blend One One
			//Blend SrcAlpha One
			CGPROGRAM
			
			// Apparently need to add this declaration
			#pragma multi_compile_fwdadd
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			
			fixed4 _Diffuse;
			fixed4 _Specular;
			float _Gloss;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
			};
			
			v2f vert(a2v v) {
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				fixed3 worldNormal = normalize(i.worldNormal);
				#ifdef USING_DIRECTIONAL_LIGHT   // 如果是平行光
					fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				#else     // 如果是点光源
					fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos.xyz);
				#endif
				
				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));
				
				fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
				fixed3 halfDir = normalize(worldLightDir + viewDir);
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);
				
				#ifdef USING_DIRECTIONAL_LIGHT   // 平行光无衰减
					fixed atten = 1.0;
				#else
					#if defined (POINT)
						// 获取光源空间下的坐标，对衰减纹理进行采样
				        float3 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1)).xyz;  
						// 在光源空间中，通过距离的平方进行采样，避免开发操作，得到衰减值
				        fixed atten = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
				    #elif defined (SPOT)
				        float4 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1));
				        fixed atten = (lightCoord.z > 0) * 
							tex2D(_LightTexture0, lightCoord.xy / lightCoord.w + 0.5).w * 
							tex2D(_LightTextureB0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
				    #else
				        fixed atten = 1.0;
				    #endif
				#endif

				return fixed4((diffuse + specular) * atten, 1.0);
			}
			
			ENDCG
		}
	}
	FallBack "Specular"
}
