Shader "KingsoftScene/SceneHigh" {
	Properties {
        _MainTex ("MainTex", 2D) = "white" {}
        _LightCtrl ("Metalic(G) Gloss(B)", 2D) = "black" {}
		_Normal ("Normal", 2D) = "bump" {}
		_Color ("Tint Color", Color) = (1.0,1.0,1.0,1.0)
		[HideInInspector] _texcoord( "", 2D ) = "white" {}

		// ----------------------------湿表面开始----------------------------
		[Toggle] _RAIN_SURFACE("启用潮湿效果", Float) = 0
		_RainSurfaceWaterMaskTex("积水深度图", 2D) = "black" {}        
		_RainSurfaceWaveTex ("水波图", 2D) = "bump" {}				
		_RainSurfaceWaveSpeed ("水波速度", Range(0, 1)) = 0.3			
		// ----------------------------湿表面结束----------------------------

		// ----------------------------雪表面开始----------------------------
		[Toggle] _SNOW_SURFACE("启用雪表面效果", Float) = 0
		[Toggle] _SNOW_SURFACE_FOOT_PRINT("雪表面时接受脚印", Float) = 0
		_SnowTex("雪贴图", 2D) = "black" {}    
		_SnowNormal("雪法线", 2D) = "bump" {}  
		_FootPrintTex ("FootPrintTex", 2D) = "white" {}  
		_FootPrintNormal ("FootPrintNormal", 2D) = "bump" {}					
		// ----------------------------雪表面结束----------------------------

    }
    SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" }
		LOD 220
		Cull Back
		//CGPROGRAM
		//#pragma target 3.0
		//#pragma multi_compile_instancing
		//#pragma surface surf Standard keepalpha addshadow fullforwardshadows 
		//#pragma fragmentoption ARB_precision_hint_fastest
		//#define FORCE_PIXEL_FOG
		//#include "../Common/ShaderFixedCommon.cginc"
		//struct Input
		//{
		//	float2 uv_texcoord;
		//};

		//uniform sampler2D _MainTex;
		//uniform float4 _MainTex_ST;
		//uniform sampler2D _Normal;
		//uniform sampler2D _LightCtrl;
		//uniform float4 _Color;
		//uniform float _GlobalBrightness;

		//void surf( Input i , inout SurfaceOutputStandard o )
		//{
		//	float2 uv_MainTex = i.uv_texcoord*_MainTex_ST.xy+_MainTex_ST.zw;
		//	float4 tex_MainTex = tex2D(_MainTex, uv_MainTex);
		//	float4 tex_Normal = tex2D(_Normal, uv_MainTex);
		//	float4 tex_LightCtrl = tex2D(_LightCtrl, uv_MainTex);
		//	o.Albedo = tex_MainTex.rgb*_Color*_GlobalBrightness;
		//	o.Normal = UnpackNormal(tex_Normal);
		//	o.Metallic = tex_LightCtrl.g;
		//	o.Smoothness = tex_LightCtrl.b;
		//	o.Alpha = 1;
		//}

		//ENDCG

		/* ------------------- 正向渲染主渲染通道，必须被包含 ------------------- */

		Pass
		{
			Name "Universal Forward"
			Tags
			{
				"LightMode" = "UniversalForward"
			}
			HLSLPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			// Pragmas
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 2.0
			#pragma multi_compile_fog
			#pragma multi_compile_instancing

			// Keywords
			#pragma multi_compile _ LIGHTMAP_ON
			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS _ADDITIONAL_OFF
			#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma multi_compile _ _SHADOWS_SOFT
			#pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE


			#define ENABLE_INTERNAL_DATA	//是否开启Surface中的INTERNAL_DATA相关功能
			#include "Packages/com.seasun.urp-upgrade/Shaders/ForwardInclude.hlsl"
			#define FORCE_PIXEL_FOG
			#include "../Common/ShaderFixedCommon.cginc"

			// ----------------------------雪表面开始----------------------------
			#pragma multi_compile _ _GLOBAL_RAIN_SURFACE 
			#pragma shader_feature _ _RAIN_SURFACE_ON	
			// ----------------------------湿表面结束----------------------------
			// ----------------------------雪表面开始----------------------------				 
			#pragma multi_compile _ _GLOBAL_SNOW_SURFACE		 
			#pragma shader_feature _ _SNOW_SURFACE_ON
			#pragma shader_feature _ _SNOW_SURFACE_FOOT_PRINT_ON							 
			// ----------------------------雪表面结束----------------------------
			#pragma fragmentoption ARB_precision_hint_nicest

			// 用于保存Surface的原始输入数据结构
			struct SurfaceDescriptionInputs
			{
				float2 uv_texcoord;

				// ----------------------------湿表面开始----------------------------
				#if _GLOBAL_RAIN_SURFACE && _RAIN_SURFACE_ON
				float3 worldPos;
				float3 worldNormal;
				float3 worldViewDir;
				INTERNAL_DATA
				#endif
				// ----------------------------湿表面结束----------------------------

				// ----------------------------雪表面开始----------------------------
				#if _GLOBAL_SNOW_SURFACE && _SNOW_SURFACE_ON
				float3 worldPos;
				INTERNAL_DATA
				#endif
				// ----------------------------雪表面结束----------------------------
			};

			// 用于存放材质包含的属性
			CBUFFER_START(UnityPerMaterial)
			uniform sampler2D _MainTex;
			uniform float4 _MainTex_ST;
			uniform sampler2D _Normal;
			uniform sampler2D _LightCtrl;
			uniform float4 _Color;

			// ----------------------------湿表面开始----------------------------
			#if _GLOBAL_RAIN_SURFACE && _RAIN_SURFACE_ON
			sampler2D _RainSurfaceWaterMaskTex;
			float4	_RainSurfaceWaterMaskTex_ST;
			sampler2D _RainSurfaceWaveTex;
			float4 _RainSurfaceWaveTex_ST;
			float _RainSurfaceWaveSpeed;
			#endif
			// ----------------------------湿表面结束----------------------------

			// ----------------------------雪表面开始----------------------------
			#if _GLOBAL_SNOW_SURFACE && _SNOW_SURFACE_ON
			sampler2D _SnowTex;
			float4	_SnowTex_ST;
			sampler2D _SnowNormal;
			float4 _SnowNormal_ST;
			#endif
			// ----------------------------湿表面结束----------------------------
			sampler2D _FootPrintTex;
			sampler2D _FootPrintNormal;
			CBUFFER_END

			// 用于存放Global属性
			uniform float _GlobalBrightness;

			// ----------------------------湿表面开始----------------------------
			#if _GLOBAL_RAIN_SURFACE && _RAIN_SURFACE_ON
			uniform float _GlobalSceneHumidness;
			uniform float4 _SceneCharacterNearestVolume;
			#include "Packages/com.seasun.ecosystem-simulate/Shaders/WeatherSimulate/WetSurface.hlsl"
			#endif
			// ----------------------------湿表面结束----------------------------

			// ----------------------------雪表面开始----------------------------
			#if _GLOBAL_SNOW_SURFACE && _SNOW_SURFACE_ON
			uniform float _GlobalSnowAmount;
			uniform sampler2D _FootPrintsTex;
			uniform float3 _FootPrintTexCenter;
			uniform float3 _FootPrintTexWorldToUv;
			uniform float _FootPrintRadius;
			uniform float4 _FootPrintCenterPos[100];
			//#include "Packages/com.seasun.ecosystem-simulate/Shaders/WeatherSimulate/WetSurface.hlsl"
			#endif
			// ----------------------------雪表面结束----------------------------


			// 根据实际使用情况开启或关闭对应的宏
			#define _NORMALMAP
			#define VARYINGS_NEED_VFACE
			//#define VARYINGS_NEED_COLOR
			#define VARYINGS_NEED_TEXCOORD0
			//#define VARYINGS_NEED_TEXCOORD2
			//#define VARYINGS_NEED_TEXCOORD3
			//#define VARYINGS_NEED_BITANGENT_WS

			// ----------------------------湿表面开始----------------------------
			#define VARYINGS_NEED_POSITION_WS	    //Surface需要顶点世界空间坐标, Varying中.positionWS
			#define VARYINGS_NEED_NORMAL_WS		    //Surface需要顶点法线世界空间坐标, Varying中.normalWS
			// ----------------------------湿表面结束----------------------------

			#include "Packages/com.seasun.urp-upgrade/Shaders/ForwardUpgrade.hlsl"


			// ----------------------------雪表面开始----------------------------
			#if _GLOBAL_SNOW_SURFACE && _SNOW_SURFACE_ON && _SNOW_SURFACE_FOOT_PRINT_ON
			#define HAVE_SURFACE_VERTEX_SHADER
			inline void SurfaceVertexShader(inout Attributes input)
			{
				float3 upVec = float3(0,1,0); 
				float difference = dot(input.normalOS,  upVec) - lerp(1, 0, _GlobalSnowAmount);
				input.positionOS.xyz += (upVec + input.normalOS) * 0.02 * saturate(difference);  
			}
			#endif
			// ----------------------------雪表面结束----------------------------

			// 根据上述宏中的属性对Surface输入参数进行赋值
			SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
			{
				SurfaceDescriptionInputs output = (SurfaceDescriptionInputs)0;
				//INTERNAL_DATA_INIT(output, input)	//对INTERNAL_DATA中的数据进行赋值
				output.uv_texcoord = input.texCoord0;

				// ----------------------------湿表面开始----------------------------
				// 潮表面，需要法线世界方向，顶点世界位置，顶点到摄像机方向，以及INTERNAL_DATA_INIT
				#if _GLOBAL_RAIN_SURFACE && _RAIN_SURFACE_ON
				output.worldPos = input.positionWS;
				output.worldNormal = input.normalWS;
				output.worldViewDir = _WorldSpaceCameraPos.xyz - input.positionWS;
				INTERNAL_DATA_INIT(output, input)
				#endif
				// ----------------------------湿表面结束----------------------------

				// ----------------------------雪表面开始----------------------------
				#if _GLOBAL_SNOW_SURFACE && _SNOW_SURFACE_ON
				output.worldPos = input.positionWS;
				INTERNAL_DATA_INIT(output, input)
				#endif
				// ----------------------------雪表面结束----------------------------
				return output;
			}

			#if _GLOBAL_SNOW_SURFACE && _SNOW_SURFACE_ON
			float3 ComputeSnowSurface(float3 mainTexColor, float2 uv0,  float3 t2w0, float3 t2w1, float3 t2w2, inout float3 bumpNormal)
			{
				float2 snowUV = uv0 * _SnowTex_ST.xy + _SnowTex_ST.zw;
				float2 snowNormalUV = uv0 *  _SnowNormal_ST.xy + _SnowNormal_ST.zw;
				float3 snowNormal = UnpackNormal(tex2D(_SnowNormal, snowNormalUV));
				float3 tangentNormal =  float3(0, 0, 1);
				float3 aseWorldNormal = normalize(half3(dot(t2w0, tangentNormal), dot(t2w1, tangentNormal), dot(t2w2, tangentNormal)));
				bumpNormal = lerp(bumpNormal , snowNormal , saturate(aseWorldNormal.y * _GlobalSnowAmount * 4));
				
				float3 worldBumpNormal = normalize(half3(dot(t2w0, bumpNormal), dot(t2w1, bumpNormal), dot(t2w2, bumpNormal)));
				float3 col = lerp( mainTexColor,  tex2D( _SnowTex, snowUV ) , saturate(worldBumpNormal.y * _GlobalSnowAmount * 4));
				return col;
			}
			#endif

			inline float2 clipRect(float2 rect) {
				int sx = step(0, rect.x) * step(rect.x, 1);
				int sy = step(0, rect.y) * step(rect.y, 1);
				int sxy = sx*sy;
				return float2(rect.x * sxy, rect.y * sxy);
			}

            sampler2D _GlobalSceneSnowFootPrintTex;
            sampler2D _GlobalSceneSnowFootPrintLifeTimeTex;
            float _SnowSurfaceFootPrintPixelPreMeter;
            float _SnowSurfaceFootPrintTexSize;
            float _SnowSurfaceGlobalSceneSize;
            float4 _SnowSurfaceFootPrintLastPosition;
            float2 _SnowSurfaceFootPrintSize;
            float _SnowSurfaceFootPrintLifeTime;
            float _SnowSurfaceFootPrintRealTime;
            float _SnowSurfaceGlobalTimeRange;

			// Surface核心函数
			SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs i)
			{
				SurfaceDescription o = InitSurfaceDescription();
				float2 uv_MainTex = i.uv_texcoord*_MainTex_ST.xy + _MainTex_ST.zw;
				float4 tex_MainTex = tex2D(_MainTex, uv_MainTex);
				float4 tex_Normal = tex2D(_Normal, uv_MainTex);
				float4 tex_LightCtrl = tex2D(_LightCtrl, uv_MainTex);
				o.Albedo = tex_MainTex.rgb*_Color*_GlobalBrightness;
				o.Normal = UnpackNormal(tex_Normal);
				o.Metallic = tex_LightCtrl.g;
				o.Smoothness = tex_LightCtrl.b;
				o.Alpha = 1;

				// ----------------------------湿表面开始----------------------------
				// 湿表面函数,得到法线和反射颜色，给到surface参数
				#if _GLOBAL_RAIN_SURFACE && _RAIN_SURFACE_ON
				float3 wetReflectionColor = float3(0,0,0);
				wetReflectionColor = ComputeWetSurface(uv_MainTex, i.worldNormal, i.worldPos, i.worldViewDir, i.internalSurfaceTtoW0, i.internalSurfaceTtoW1, i.internalSurfaceTtoW2, o.Normal);
				o.Albedo = o.Albedo + wetReflectionColor;
				o.Normal = o.Normal;
				#endif
				// ----------------------------湿表面结束----------------------------
					  
				// ----------------------------雪表面开始----------------------------
				#if _GLOBAL_SNOW_SURFACE && _SNOW_SURFACE_ON
				float3 snowColor = float3(0,0,0);
				snowColor = ComputeSnowSurface(o.Albedo, uv_MainTex, i.internalSurfaceTtoW0, i.internalSurfaceTtoW1, i.internalSurfaceTtoW2, o.Normal);
				o.Albedo = snowColor;
				o.Normal = o.Normal;
				o.Metallic = o.Metallic * (1 - _GlobalSnowAmount);
				o.Smoothness = o.Smoothness * (1 - _GlobalSnowAmount);

                //float2 characterPosOS = _SnowSurfaceFootPrintLastPosition.xz * _SnowSurfaceFootPrintPixelPreMeter;
                //float2 pixelPosOS = i.worldPos.xz * _SnowSurfaceFootPrintPixelPreMeter;

                //// 变换到脚印贴图UV 
                //float2 deltaUV = (pixelPosOS - characterPosOS + _SnowSurfaceFootPrintTexSize / 2) / _SnowSurfaceFootPrintTexSize;
                //if (deltaUV.x >= 0 && deltaUV.y >= 0 && deltaUV.x <= 1 && deltaUV.y <= 1)
                //{
                //    float4 footprintLifeTimeVal = tex2D(_GlobalSceneSnowFootPrintLifeTimeTex, deltaUV);
                //    float lifeTime = (footprintLifeTimeVal.r + footprintLifeTimeVal.g * 256.0f) / 257.0f;
                //    if (lifeTime > 0)
                //    {
                //        float4 footprintVal = tex2D(_GlobalSceneSnowFootPrintTex, deltaUV);
                //        float2 footprintPosVal = float2((footprintVal.r + footprintVal.g * 256.0f) / 257.0f, (footprintVal.b + footprintVal.a * 256.0f) / 257.0f) * _SnowSurfaceGlobalSceneSize;
                //        float2 delta = i.worldPos.xz - footprintPosVal;
                //        float2 deltaAbs = abs(delta);
                        
                //        float2 range = _SnowSurfaceFootPrintSize;
                        
                //        //o.Albedo = float3(1 , 0 , 0);

                //        float2 fpUV = float2(delta.x, delta.y) / range / 2 + 0.5f;  
                //        if (fpUV.x >= 0 && fpUV.x <= 1 && fpUV.y >= 0 & fpUV.y <= 1)
                //        {
                //            //o.Albedo = float3(1 , 0 , 0);
                //            float radianY = ((footprintLifeTimeVal.b + footprintLifeTimeVal.a * 256.0f) / 257.0f * 360.0f) * 0.0174532924f;
  
		              //      float cosAngle = cos(radianY);
		              //      float sinAngle = sin(radianY);
		              //      float2x2 rot = float2x2(cosAngle, -sinAngle, sinAngle, cosAngle);
                    
		              //      fpUV = mul(rot , fpUV - float2(0.5, 0.5)) + float2(0.5, 0.5);;
                                                    
                //            float3 addAlbedo = tex2D(_FootPrintTex, fpUV);   
                            
                //            float instensity = 1 - (_SnowSurfaceFootPrintRealTime - lifeTime) / _SnowSurfaceFootPrintLifeTime * _SnowSurfaceGlobalTimeRange ;
                            
                //            // 没有贴图用 暂时用现有的脚印高度图调整效果
                //            o.Albedo -= step(addAlbedo , 0.3) * addAlbedo * instensity;
                            
                //            float3 addNormal = UnpackNormal(tex2D(_FootPrintNormal, fpUV));                         
                //            o.Normal += addNormal * instensity;
                //        }
                //    }
                //}
                
				// 脚印图坐标中，像素点的位置和UV
				float3 wPos = i.worldPos - _FootPrintTexCenter;
				float2 uv = wPos.xz * _FootPrintTexWorldToUv;
				float4 fpCol = 0;
				if(uv.x >=0 && uv.x <= 1 && uv.y >= 0 && uv.y <= 1)  // 在脚印图范围内
				{
					// 从脚印图获取当前点的信息，可以是位置，方向等
					fpCol = tex2D(_FootPrintsTex, uv);
					if(fpCol.a > 0)
					{
						float3 Pos = (fpCol - 0.5) * 1024;			// 转到世界坐标
						// 每个像素他所属脚印贴图的中心点(世界坐标)
						float3 centerPos = float3(Pos.x, i.worldPos.y, Pos.z); 
						centerPos = _FootPrintCenterPos[fpCol.x].xyz; // 用数组的形式获取脚印位置

						float2 uvPos = (i.worldPos - centerPos).xz / _FootPrintRadius;	  // 计算脚印UV，旋转
						float angel =  -fpCol.y * 360 * 0.0174532924;
						float fcos = cos(angel);
						float fsin = sin(angel);
						
						//float2 fpUv = float2(uvPos.x * fcos + uvPos.y * fsin, uvPos.x * -fsin + uvPos.y * fcos);
						float2 fpUv;
						float2x2 rot = float2x2(fcos, -fsin, fsin, fcos);
						fpUv = mul(rot , uvPos);
						fpUv = (fpUv + 1) * 0.5;
						
						// 脚印颜色融合,法线，可配合乘积叠加量
						float4 nCol = tex2D(_FootPrintTex, fpUv);	
						o.Albedo = o.Albedo - step(nCol , 0.3) * nCol;
						float3 addNormal = UnpackNormal(tex2D(_FootPrintNormal, fpUv));
						o.Normal = o.Normal + addNormal;
					}
				}
		

				#endif
				// ----------------------------雪表面结束----------------------------

				return o;
			}

			#include "Packages/com.seasun.urp-upgrade/Shaders/Varyings.hlsl"
			#include "Packages/com.seasun.urp-upgrade/Shaders/PBRForwardPass.hlsl"

			ENDHLSL
		}

		/* ------------------- 实时阴影通道，根据情况决定是否使用 ------------------- */

		Pass
		{
			Name "ShadowCaster"
			Tags
			{
				"LightMode" = "ShadowCaster"
			}

			Blend One Zero, One Zero
			Cull Back
			ZTest LEqual
			ZWrite On

			HLSLPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			// Pragmas
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 2.0
			#pragma multi_compile_instancing

			// Includes
			#include "Packages/com.seasun.urp-upgrade/Shaders/ShadowInclude.hlsl"

			// 用于保存Surface的原始输入数据结构
			struct SurfaceDescriptionInputs
			{

			};

			// 用于存放材质包含的属性
			CBUFFER_START(UnityPerMaterial)

			CBUFFER_END

			// 用于存放Global属性
			uniform float _GlobalBrightness;

			#include "Packages/com.seasun.urp-upgrade/Shaders/ShadowUpgrade.hlsl"

			// 对应Surface的Vert，根据情况开启
			#define HAVE_SURFACE_VERTEX_SHADER
			/*
				struct Attributes
				{
					float3 positionOS : POSITION;	//Default
					float3 normalOS : NORMAL;		//ATTRIBUTES_NEED_NORMAL
					float4 tangentOS : TANGENT;		//ATTRIBUTES_NEED_TANGENT
					float4 color : COLOR;			//VARYINGS_NEED_COLOR
					float4 uv0 : TEXCOORD0;			//VARYINGS_NEED_TEXCOORD0
					float4 uv1 : TEXCOORD1;			//VARYINGS_NEED_TEXCOORD1
					float4 uv2 : TEXCOORD2;			//VARYINGS_NEED_TEXCOORD2
				};
			*/
			inline void SurfaceVertexShader(inout Attributes input)
			{

			}

			// 根据上述宏中的属性对Surface输入参数进行赋值
			SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
			{
				SurfaceDescriptionInputs output = (SurfaceDescriptionInputs)0;

				return output;
			}

			// Surface核心函数
			SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs i)
			{
				SurfaceDescription o = InitSurfaceDescription();

				return o;
			}

			#include "Packages/com.seasun.urp-upgrade/Shaders/Varyings.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShadowCasterPass.hlsl"

			ENDHLSL
		}

		/* ------------------- 获取深度通道，必须包含 ------------------- */

		Pass
		{
			Name "DepthOnly"
			Tags
			{
				"LightMode" = "DepthOnly"
			}

			Blend One Zero, One Zero
			Cull Back
			ZTest LEqual
			ZWrite On
			ColorMask 0

			HLSLPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			// Pragmas
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 2.0
			#pragma multi_compile_instancing

			// Includes
			#include "Packages/com.seasun.urp-upgrade/Shaders/DepthOnlyInclude.hlsl"

			// 用于保存Surface的原始输入数据结构
			struct SurfaceDescriptionInputs
			{

			};

			// 用于存放材质包含的属性
			CBUFFER_START(UnityPerMaterial)

			CBUFFER_END

			// 用于存放Global属性

			#include "Packages/com.seasun.urp-upgrade/Shaders/DepthOnlyUpgrade.hlsl"

			// 对应Surface的Vert，根据情况开启
			#define HAVE_SURFACE_VERTEX_SHADER
			/*
				struct Attributes
				{
					float3 positionOS : POSITION;	//Default
					float3 normalOS : NORMAL;		//ATTRIBUTES_NEED_NORMAL
					float4 tangentOS : TANGENT;		//ATTRIBUTES_NEED_TANGENT
					float4 color : COLOR;			//VARYINGS_NEED_COLOR
					float4 uv0 : TEXCOORD0;			//VARYINGS_NEED_TEXCOORD0
					float4 uv1 : TEXCOORD1;			//VARYINGS_NEED_TEXCOORD1
					float4 uv2 : TEXCOORD2;			//VARYINGS_NEED_TEXCOORD2
				};
			*/
			inline void SurfaceVertexShader(inout Attributes input)
			{

			}

			// 根据上述宏中的属性对Surface输入参数进行赋值
			SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
			{
				SurfaceDescriptionInputs output = (SurfaceDescriptionInputs)0;

				return output;
			}

			// Surface核心函数
			SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs i)
			{
				SurfaceDescription o = InitSurfaceDescription();

				return o;
			}

			#include "Packages/com.seasun.urp-upgrade/Shaders/Varyings.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthOnlyPass.hlsl"

			ENDHLSL
		}

	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" }
		LOD 210
		Cull Back
		//CGPROGRAM
		//#pragma target 3.0
		//#pragma multi_compile_instancing
		//#pragma surface surf BlinnPhong keepalpha addshadow fullforwardshadows 
		//#pragma fragmentoption ARB_precision_hint_fastest
		//#define FORCE_PIXEL_FOG
		//#include "../Common/ShaderFixedCommon.cginc"
		//struct Input
		//{
		//	float2 uv_texcoord;
		//};
		//uniform sampler2D _MainTex;
		//uniform float4 _MainTex_ST;
		//uniform float4 _Color;
		//uniform float _GlobalBrightness;


		//void surf( Input i , inout SurfaceOutput o )
		//{
		//	float2 uv_MainTex = i.uv_texcoord * _MainTex_ST.xy + _MainTex_ST.zw;
		//	o.Albedo = tex2D( _MainTex, uv_MainTex ).rgb*_Color*_GlobalBrightness;
		//	o.Alpha = 1;
		//}

		//ENDCG


		/* ------------------- 正向渲染主渲染通道，必须被包含 ------------------- */

		Pass
		{
			Name "Universal Forward"
			Tags
			{
				"LightMode" = "UniversalForward"
			}
			HLSLPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			// Pragmas
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 2.0
			#pragma multi_compile_fog
			#pragma multi_compile_instancing

			// Keywords
			#pragma multi_compile _ LIGHTMAP_ON
			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS _ADDITIONAL_OFF
			#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma multi_compile _ _SHADOWS_SOFT
			#pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE

			// Includes
			//#define ENABLE_INTERNAL_DATA	//是否开启Surface中的INTERNAL_DATA相关功能
			#include "Packages/com.seasun.urp-upgrade/Shaders/ForwardInclude.hlsl"

			#define FORCE_PIXEL_FOG
			#include "../Common/ShaderFixedCommon.cginc"

			// 用于保存Surface的原始输入数据结构
			struct SurfaceDescriptionInputs
			{
				float2 uv_texcoord;
			};

			// 用于存放材质包含的属性
			CBUFFER_START(UnityPerMaterial)
			uniform sampler2D _MainTex;
			uniform float4 _MainTex_ST;
			uniform float4 _Color;
			//uniform float _GlobalBrightness;
			CBUFFER_END

			// 用于存放Global属性
			uniform float _GlobalBrightness;

			// 根据实际使用情况开启或关闭对应的宏
			//#define _NORMALMAP
			//#define VARYINGS_NEED_VFACE
			//#define VARYINGS_NEED_COLOR
			#define VARYINGS_NEED_TEXCOORD0
			//#define VARYINGS_NEED_TEXCOORD2
			//#define VARYINGS_NEED_TEXCOORD3
			//#define VARYINGS_NEED_BITANGENT_WS

			#include "Packages/com.seasun.urp-upgrade/Shaders/ForwardUpgrade.hlsl"

			// 对应Surface的Vert，根据情况开启
			//#define HAVE_SURFACE_VERTEX_SHADER
			/*
				struct Attributes
				{
					float3 positionOS : POSITION;	//Default
					float3 normalOS : NORMAL;		//ATTRIBUTES_NEED_NORMAL
					float4 tangentOS : TANGENT;		//ATTRIBUTES_NEED_TANGENT
					float4 color : COLOR;			//VARYINGS_NEED_COLOR
					float4 uv0 : TEXCOORD0;			//VARYINGS_NEED_TEXCOORD0
					float4 uv1 : TEXCOORD1;			//VARYINGS_NEED_TEXCOORD1
					float4 uv2 : TEXCOORD2;			//VARYINGS_NEED_TEXCOORD2
				};
			*/
			inline void SurfaceVertexShader(inout Attributes input)
			{

			}

			// 根据上述宏中的属性对Surface输入参数进行赋值
			SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
			{
				SurfaceDescriptionInputs output = (SurfaceDescriptionInputs)0;
				//INTERNAL_DATA_INIT(output, input)	//对INTERNAL_DATA中的数据进行赋值
				output.uv_texcoord = input.texCoord0;
				return output;
			}

			// Surface核心函数
			SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs i)
			{
				SurfaceDescription o = InitSurfaceDescription();
				float2 uv_MainTex = i.uv_texcoord * _MainTex_ST.xy + _MainTex_ST.zw;
				o.Albedo = tex2D(_MainTex, uv_MainTex).rgb*_Color*_GlobalBrightness;
				o.Alpha = 1;
				return o;
			}

			#include "Packages/com.seasun.urp-upgrade/Shaders/Varyings.hlsl"
			#include "Packages/com.seasun.urp-upgrade/Shaders/PBRForwardPass.hlsl"

			ENDHLSL
		}

		/* ------------------- 实时阴影通道，根据情况决定是否使用 ------------------- */

		Pass
		{
			Name "ShadowCaster"
			Tags
			{
				"LightMode" = "ShadowCaster"
			}

			Blend One Zero, One Zero
			Cull Back
			ZTest LEqual
			ZWrite On

			HLSLPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			// Pragmas
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 2.0
			#pragma multi_compile_instancing

			// Includes
			#include "Packages/com.seasun.urp-upgrade/Shaders/ShadowInclude.hlsl"

			// 用于保存Surface的原始输入数据结构
			struct SurfaceDescriptionInputs
			{

			};

			// 用于存放材质包含的属性
			CBUFFER_START(UnityPerMaterial)

			CBUFFER_END

			// 用于存放Global属性
			uniform float _GlobalBrightness;

			#include "Packages/com.seasun.urp-upgrade/Shaders/ShadowUpgrade.hlsl"

			// 对应Surface的Vert，根据情况开启
			#define HAVE_SURFACE_VERTEX_SHADER
			/*
				struct Attributes
				{
					float3 positionOS : POSITION;	//Default
					float3 normalOS : NORMAL;		//ATTRIBUTES_NEED_NORMAL
					float4 tangentOS : TANGENT;		//ATTRIBUTES_NEED_TANGENT
					float4 color : COLOR;			//VARYINGS_NEED_COLOR
					float4 uv0 : TEXCOORD0;			//VARYINGS_NEED_TEXCOORD0
					float4 uv1 : TEXCOORD1;			//VARYINGS_NEED_TEXCOORD1
					float4 uv2 : TEXCOORD2;			//VARYINGS_NEED_TEXCOORD2
				};
			*/
			inline void SurfaceVertexShader(inout Attributes input)
			{

			}

			// 根据上述宏中的属性对Surface输入参数进行赋值
			SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
			{
				SurfaceDescriptionInputs output = (SurfaceDescriptionInputs)0;

				return output;
			}

			// Surface核心函数
			SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs i)
			{
				SurfaceDescription o = InitSurfaceDescription();

				return o;
			}

			#include "Packages/com.seasun.urp-upgrade/Shaders/Varyings.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShadowCasterPass.hlsl"

			ENDHLSL
		}

		/* ------------------- 获取深度通道，必须包含 ------------------- */

		Pass
		{
			Name "DepthOnly"
			Tags
			{
				"LightMode" = "DepthOnly"
			}

			Blend One Zero, One Zero
			Cull Back
			ZTest LEqual
			ZWrite On
			ColorMask 0

			HLSLPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			// Pragmas
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 2.0
			#pragma multi_compile_instancing

			// Includes
			#include "Packages/com.seasun.urp-upgrade/Shaders/DepthOnlyInclude.hlsl"

			// 用于保存Surface的原始输入数据结构
			struct SurfaceDescriptionInputs
			{

			};

			// 用于存放材质包含的属性
			CBUFFER_START(UnityPerMaterial)

			CBUFFER_END

			// 用于存放Global属性

			#include "Packages/com.seasun.urp-upgrade/Shaders/DepthOnlyUpgrade.hlsl"

			// 对应Surface的Vert，根据情况开启
			#define HAVE_SURFACE_VERTEX_SHADER
			/*
				struct Attributes
				{
					float3 positionOS : POSITION;	//Default
					float3 normalOS : NORMAL;		//ATTRIBUTES_NEED_NORMAL
					float4 tangentOS : TANGENT;		//ATTRIBUTES_NEED_TANGENT
					float4 color : COLOR;			//VARYINGS_NEED_COLOR
					float4 uv0 : TEXCOORD0;			//VARYINGS_NEED_TEXCOORD0
					float4 uv1 : TEXCOORD1;			//VARYINGS_NEED_TEXCOORD1
					float4 uv2 : TEXCOORD2;			//VARYINGS_NEED_TEXCOORD2
				};
			*/
			inline void SurfaceVertexShader(inout Attributes input)
			{

			}

			// 根据上述宏中的属性对Surface输入参数进行赋值
			SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
			{
				SurfaceDescriptionInputs output = (SurfaceDescriptionInputs)0;

				return output;
			}

			// Surface核心函数
			SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs i)
			{
				SurfaceDescription o = InitSurfaceDescription();

				return o;
			}

			#include "Packages/com.seasun.urp-upgrade/Shaders/Varyings.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthOnlyPass.hlsl"

			ENDHLSL
		}

	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" "IsEmissive" = "true"  }
		LOD 200
		Cull Back
		//CGPROGRAM
		//#include "UnityShaderVariables.cginc"
		//#pragma target 3.0
		//#pragma multi_compile_instancing
		//#pragma surface surf Unlit keepalpha 
		//#pragma fragmentoption ARB_precision_hint_fastest
		//#define FORCE_PIXEL_FOG
		//#include "../Common/ShaderFixedCommon.cginc"
		//struct Input
		//{
		//	float2 uv_texcoord;
		//};

		//uniform sampler2D _MainTex;
		//uniform float4 _MainTex_ST;
		//uniform float4 _Color;
		//uniform float _GlobalBrightness;

		//inline fixed4 LightingUnlit( SurfaceOutput s, half3 lightDir, half atten )
		//{
		//	return fixed4 ( 0, 0, 0, s.Alpha );
		//}

		//void surf( Input i , inout SurfaceOutput o )
		//{
		//	float2 uv_MainTex = i.uv_texcoord * _MainTex_ST.xy + _MainTex_ST.zw;
		//	o.Emission = tex2D( _MainTex, uv_MainTex ).rgb * _Color *_GlobalBrightness;
		//	o.Alpha = 1;
		//}

		//ENDCG

		/* ------------------- 正向渲染主渲染通道，必须被包含 ------------------- */

		Pass
		{
			Name "Universal Forward"
			Tags
			{
				"LightMode" = "UniversalForward"
			}
			HLSLPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			// Pragmas
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 2.0
			#pragma multi_compile_fog
			#pragma multi_compile_instancing

			// Keywords
			#pragma multi_compile _ LIGHTMAP_ON
			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS _ADDITIONAL_OFF
			#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma multi_compile _ _SHADOWS_SOFT
			#pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE

			// Includes
			//#define ENABLE_INTERNAL_DATA	//是否开启Surface中的INTERNAL_DATA相关功能
			#include "Packages/com.seasun.urp-upgrade/Shaders/ForwardInclude.hlsl"
			#define FORCE_PIXEL_FOG
			#include "../Common/ShaderFixedCommon.cginc"

			// 用于保存Surface的原始输入数据结构
			struct SurfaceDescriptionInputs
			{
				float2 uv_texcoord;
			};

			// 用于存放材质包含的属性
			CBUFFER_START(UnityPerMaterial)
			uniform sampler2D _MainTex;
			uniform float4 _MainTex_ST;
			uniform float4 _Color;
			//uniform float _GlobalBrightness;
			CBUFFER_END

			// 用于存放Global属性
			uniform float _GlobalBrightness;

			// 根据实际使用情况开启或关闭对应的宏
			//#define _NORMALMAP
			//#define VARYINGS_NEED_VFACE
			//#define VARYINGS_NEED_COLOR
			#define VARYINGS_NEED_TEXCOORD0
			//#define VARYINGS_NEED_TEXCOORD2
			//#define VARYINGS_NEED_TEXCOORD3
			//#define VARYINGS_NEED_BITANGENT_WS

			#include "Packages/com.seasun.urp-upgrade/Shaders/ForwardUpgrade.hlsl"

			// 对应Surface的Vert，根据情况开启
			//#define HAVE_SURFACE_VERTEX_SHADER
			/*
				struct Attributes
				{
					float3 positionOS : POSITION;	//Default
					float3 normalOS : NORMAL;		//ATTRIBUTES_NEED_NORMAL
					float4 tangentOS : TANGENT;		//ATTRIBUTES_NEED_TANGENT
					float4 color : COLOR;			//VARYINGS_NEED_COLOR
					float4 uv0 : TEXCOORD0;			//VARYINGS_NEED_TEXCOORD0
					float4 uv1 : TEXCOORD1;			//VARYINGS_NEED_TEXCOORD1
					float4 uv2 : TEXCOORD2;			//VARYINGS_NEED_TEXCOORD2
				};
			*/
			inline void SurfaceVertexShader(inout Attributes input)
			{

			}

			// 根据上述宏中的属性对Surface输入参数进行赋值
			SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
			{
				SurfaceDescriptionInputs output = (SurfaceDescriptionInputs)0;
				//INTERNAL_DATA_INIT(output, input)	//对INTERNAL_DATA中的数据进行赋值
				output.uv_texcoord = input.texCoord0;
				return output;
			}

			// Surface核心函数
			SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs i)
			{
				SurfaceDescription o = InitSurfaceDescription();
				float2 uv_MainTex = i.uv_texcoord * _MainTex_ST.xy + _MainTex_ST.zw;
				o.Emission = tex2D(_MainTex, uv_MainTex).rgb * _Color *_GlobalBrightness;
				o.Alpha = 1;
				return o;
			}


			#include "Packages/com.seasun.urp-upgrade/Shaders/Varyings.hlsl"
			#include "Packages/com.seasun.urp-upgrade/Shaders/PBRForwardPass.hlsl"

			ENDHLSL
		}

		/* ------------------- 实时阴影通道，根据情况决定是否使用 ------------------- */

		Pass
		{
			Name "ShadowCaster"
			Tags
			{
				"LightMode" = "ShadowCaster"
			}

			Blend One Zero, One Zero
			Cull Back
			ZTest LEqual
			ZWrite On

			HLSLPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			// Pragmas
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 2.0
			#pragma multi_compile_instancing

			// Includes
			#include "Packages/com.seasun.urp-upgrade/Shaders/ShadowInclude.hlsl"

			// 用于保存Surface的原始输入数据结构
			struct SurfaceDescriptionInputs
			{

			};

			// 用于存放材质包含的属性
			CBUFFER_START(UnityPerMaterial)

			CBUFFER_END

			// 用于存放Global属性
			uniform float _GlobalBrightness;

			#include "Packages/com.seasun.urp-upgrade/Shaders/ShadowUpgrade.hlsl"

			// 对应Surface的Vert，根据情况开启
			#define HAVE_SURFACE_VERTEX_SHADER
			/*
				struct Attributes
				{
					float3 positionOS : POSITION;	//Default
					float3 normalOS : NORMAL;		//ATTRIBUTES_NEED_NORMAL
					float4 tangentOS : TANGENT;		//ATTRIBUTES_NEED_TANGENT
					float4 color : COLOR;			//VARYINGS_NEED_COLOR
					float4 uv0 : TEXCOORD0;			//VARYINGS_NEED_TEXCOORD0
					float4 uv1 : TEXCOORD1;			//VARYINGS_NEED_TEXCOORD1
					float4 uv2 : TEXCOORD2;			//VARYINGS_NEED_TEXCOORD2
				};
			*/
			inline void SurfaceVertexShader(inout Attributes input)
			{

			}

			// 根据上述宏中的属性对Surface输入参数进行赋值
			SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
			{
				SurfaceDescriptionInputs output = (SurfaceDescriptionInputs)0;

				return output;
			}

			// Surface核心函数
			SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs i)
			{
				SurfaceDescription o = InitSurfaceDescription();

				return o;
			}

			#include "Packages/com.seasun.urp-upgrade/Shaders/Varyings.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShadowCasterPass.hlsl"

			ENDHLSL
		}

		/* ------------------- 获取深度通道，必须包含 ------------------- */

		Pass
		{
			Name "DepthOnly"
			Tags
			{
				"LightMode" = "DepthOnly"
			}

			Blend One Zero, One Zero
			Cull Back
			ZTest LEqual
			ZWrite On
			ColorMask 0

			HLSLPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			// Pragmas
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 2.0
			#pragma multi_compile_instancing

			// Includes
			#include "Packages/com.seasun.urp-upgrade/Shaders/DepthOnlyInclude.hlsl"

			// 用于保存Surface的原始输入数据结构
			struct SurfaceDescriptionInputs
			{

			};

			// 用于存放材质包含的属性
			CBUFFER_START(UnityPerMaterial)

			CBUFFER_END

			// 用于存放Global属性

			#include "Packages/com.seasun.urp-upgrade/Shaders/DepthOnlyUpgrade.hlsl"

			// 对应Surface的Vert，根据情况开启
			#define HAVE_SURFACE_VERTEX_SHADER
			/*
				struct Attributes
				{
					float3 positionOS : POSITION;	//Default
					float3 normalOS : NORMAL;		//ATTRIBUTES_NEED_NORMAL
					float4 tangentOS : TANGENT;		//ATTRIBUTES_NEED_TANGENT
					float4 color : COLOR;			//VARYINGS_NEED_COLOR
					float4 uv0 : TEXCOORD0;			//VARYINGS_NEED_TEXCOORD0
					float4 uv1 : TEXCOORD1;			//VARYINGS_NEED_TEXCOORD1
					float4 uv2 : TEXCOORD2;			//VARYINGS_NEED_TEXCOORD2
				};
			*/
			inline void SurfaceVertexShader(inout Attributes input)
			{

			}

			// 根据上述宏中的属性对Surface输入参数进行赋值
			SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
			{
				SurfaceDescriptionInputs output = (SurfaceDescriptionInputs)0;

				return output;
			}

			// Surface核心函数
			SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs i)
			{
				SurfaceDescription o = InitSurfaceDescription();

				return o;
			}

			#include "Packages/com.seasun.urp-upgrade/Shaders/Varyings.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthOnlyPass.hlsl"

			ENDHLSL
		}
	}
	
	FallBack "Hidden/InternalErrorShader"

}