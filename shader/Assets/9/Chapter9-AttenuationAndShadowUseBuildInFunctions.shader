// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// 此例子，针对base和add统一管理光照衰减和阴影

// 产生阴影必须开启CastShadows,默认是单面，也可以设置双面TwoSlided；shdaer中必须包含ShadowCaster的Pass,这样才能被生成深度信息
// 接受阴影必须开启ReceiveShadows，这样才能通过TRANSFER_SHADOW进行采样阴影颜色

// 光照阴影三剑客
// SHADOW_COORDS   声明纹理坐标

// TRANSFER_SHADOW 不同平台有所差异，会调用内置的computeScreenPos来计算纹理坐标
// 如果平台不支持屏幕空间的阴影纹理映射技术，则会用传统的阴影映射技术
// 把顶点坐标从模型空间变换到光源空间，最后存储到SHADOW_COORDS中

// UNITY_LIGHT_ATTENUATION 1.包含光照衰减 2.使用SHADOW_COORDS对相关的纹理进行采样，得到阴影信息
Shader "Unity Shaders Book/Chapter 9/Attenuation And Shadow Use Build-in Functions" {
	Properties {
		_Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
		_Specular ("Specular", Color) = (1, 1, 1, 1)
		_Gloss ("Gloss", Range(8.0, 256)) = 20
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		
		Pass {
			// Pass for ambient light & first pixel light (directional light)
			Tags { "LightMode"="ForwardBase" }
		
			CGPROGRAM
			
			// Apparently need to add this declaration
			// 可以保证使用光照衰减等光照变量被正确赋值，不可缺少
			#pragma multi_compile_fwdbase	
			
			#pragma vertex vert
			#pragma fragment frag
			
			// Need these files to get built-in macros
			#include "Lighting.cginc"
			#include "AutoLight.cginc"     // 计算阴影所需要的宏
			
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
				SHADOW_COORDS(2)
			};
			
			v2f vert(a2v v) {
			 	v2f o;
			 	o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
			 	
			 	o.worldNormal = UnityObjectToWorldNormal(v.normal);
			 	
			 	o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
			 	
			 	// Pass shadow coordinates to pixel shader
			 	TRANSFER_SHADOW(o);
			 	
			 	return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				
			 	fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));

			 	fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
			 	fixed3 halfDir = normalize(worldLightDir + viewDir);
			 	fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

				// UNITY_LIGHT_ATTENUATION not only compute attenuation, but also shadow infos
				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
				
				return fixed4(ambient + (diffuse + specular) * atten, 1.0);
			}
			
			ENDCG
		}
	
		Pass {
			// Pass for other pixel lights
			Tags { "LightMode"="ForwardAdd" }
			
			Blend One One
		
			CGPROGRAM
			
			// Apparently need to add this declaration
			#pragma multi_compile_fwdadd
			// Use the line below to add shadows for point and spot lights
			// 使用下面的指令，给点光源和聚光灯添加阴影
//			#pragma multi_compile_fwdadd_fullshadows
			
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
				SHADOW_COORDS(2)
			};
			
			v2f vert(a2v v) {
			 	v2f o;
			 	o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
			 	
			 	o.worldNormal = UnityObjectToWorldNormal(v.normal);
			 	
			 	o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
			 	
			 	// Pass shadow coordinates to pixel shader
			 	TRANSFER_SHADOW(o);
			 	
			 	return o;
			}
			
			fixed4 frag(v2f i) : SV_Target {
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				
			 	fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));

			 	fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
			 	fixed3 halfDir = normalize(worldLightDir + viewDir);
			 	fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

				// UNITY_LIGHT_ATTENUATION not only compute attenuation, but also shadow infos
				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
			 	
				return fixed4((diffuse + specular) * atten, 1.0);
			}
			
			ENDCG
		}
	}
	FallBack "Specular"
}
