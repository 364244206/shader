// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "UI/UIOutline" 
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _Color ("Tint", Color) = (1, 1, 1, 1)

        _StencilComp ("Stencil Comparison", Float) = 8
        _Stencil ("Stencil ID", Float) = 0
        _StencilOp ("Stencil Operation", Float) = 0
        _StencilWriteMask ("Stencil Write Mask", Float) = 255
        _StencilReadMask ("Stencil Read Mask", Float) = 255

        _ColorMask ("Color Mask", Float) = 15

        [Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("Use Alpha Clip", Float) = 0

		_BlurFactor ("BlurFactor", Float) = 1
		_ColorFactor ("colorFactor", Float) = 1	

		_Mask (" _Mask", 2D) = "white" {}
    }

    SubShader
    {
        Tags
        { 
            "Queue"="Transparent" 
            "IgnoreProjector"="True" 
            "RenderType"="Transparent" 
            "PreviewType"="Plane"
            "CanUseSpriteAtlas"="True"
        }
        
        Stencil
        {
            Ref [_Stencil]
            Comp [_StencilComp]
            Pass [_StencilOp] 
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }

        Cull Off
        Lighting Off
        ZWrite Off
        ZTest [unity_GUIZTestMode]
        Blend SrcAlpha OneMinusSrcAlpha
        ColorMask [_ColorMask]
	  
		Pass
        {
            Name "OUTLINE"

			Blend One SrcAlpha		// 源RGBA * 1 + 背景RGBA * 源A

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			#pragma shader_feature __ FASTBLUR MEDIUMBLUR DETAILBLUR
			#include "UnityCG.cginc"

            sampler2D _MainTex;
			float4 _MainTex_TexelSize;

            fixed4 _Color;
            fixed4 _TextureSampleAdd;
 
			float _BlurFactor;
			float _ColorFactor;

			sampler2D _Mask;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
				float2 texcoord1 : TEXCOORD1;
                fixed4 color : COLOR;	
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 texcoord : TEXCOORD0;
				float2 texcoord1 : TEXCOORD1;
                fixed4 color : COLOR;
            };

            v2f vert(appdata IN)
            {
                v2f o;
				o.vertex = UnityObjectToClipPos(IN.vertex);
                o.texcoord = IN.texcoord;
			    o.texcoord1 = IN.texcoord1;
                o.color = IN.color;
                return o;
            }

			fixed4 Tex2DBlurring (sampler2D tex, half2 texcood, half2 blur, half4 mask)
			{
				#if FASTBLUR
				const int KERNEL_SIZE = 3;
				const float KERNEL_[3] = { 0.4566, 1.0, 0.4566};
				#elif MEDIUMBLUR
				const int KERNEL_SIZE = 7;
				const float KERNEL_[7] = { 0.1719, 0.4566, 0.8204, 1.0, 0.8204, 0.4566, 0.1719};
				#elif DETAILBLUR
				const int KERNEL_SIZE = 13;
				const float KERNEL_[13] = { 0.0438, 0.1138, 0.2486, 0.4566, 0.7046, 0.9141, 1.0, 0.9141, 0.7046, 0.4566, 0.2486, 0.1138, 0.0438};
				#else
				const int KERNEL_SIZE = 1;
				const float KERNEL_[1] = { 1.0 };
				#endif

				float4 o = 0;
				float sum = 0;
				float2 shift = 0;
				for(int x = 0; x < KERNEL_SIZE; x++)
				{
					shift.x = blur.x * (float(x) - KERNEL_SIZE/2);
					for(int y = 0; y < KERNEL_SIZE; y++)
					{
						shift.y = blur.y * (float(y) - KERNEL_SIZE/2);
						float2 uv = texcood + shift;
						float weight = KERNEL_[x] * KERNEL_[y];
						sum += weight;
	
						o += tex2D(tex, uv) * weight;
					}
				}
				return o / sum;
			}

			fixed4 Tex2DBlurring (sampler2D tex, half2 texcood, half2 blur)
			{
				return Tex2DBlurring(tex, texcood, blur, half4(0,0,1,1));
			}


			fixed4 frag(v2f IN) : SV_Target
			{
				// UV1的x=0用于识别主纹理，主纹理模糊值为0
				fixed4 color = (Tex2DBlurring(_MainTex, IN.texcoord, IN.texcoord1.x  * _BlurFactor * 10 * _MainTex_TexelSize.xy) + _TextureSampleAdd);
				// 边缘色和主色， 按照CPU方式是下面这样。
				/*
				if(IN.texcoord1.x > 0.9f)
				{
					color.rgb = IN.color.rgb;
				}
				else
				{
					color.rgb = IN.color.rgb * color.rgb;
				}
				*/

				// 按照GPU方式，边缘只取输入的颜色，主色通过_ColorFactor可以扩展多种叠加方式
				color.rgb = lerp(IN.color.rgb , color.rgb, (1-IN.texcoord1.x) * (1 - _ColorFactor));
				color.a *= IN.color.a;		// 需要自己的a通道
			
				// 单pass透明add
				color.rgb = color.rgb * color.a;
				if (color.a >= 1.0f)
				{
					color.a = 1 - color.a;
				}
				else
				{
					color.a = 1;
				}
		
				return color;
			}
			ENDCG
		}
    }
}