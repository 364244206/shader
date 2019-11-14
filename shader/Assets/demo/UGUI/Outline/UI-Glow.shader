Shader "UI/UIGlow" 
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

		_OuterGlowColor ("Outline Color", Color) = (1, 1, 1, 1)

		_GlowFactor ("Outline A", Float) = 8
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
        //Blend SrcAlpha OneMinusSrcAlpha
        ColorMask [_ColorMask]
	  
		Pass
        {
            Name "OUTLINE"
			//Blend SrcAlpha One
			Blend One SrcAlpha		// 源RGBA * 1 + 背景RGBA * 源A

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			#include "UnityCG.cginc"

            sampler2D _MainTex;
            fixed4 _Color;
            fixed4 _TextureSampleAdd;
            float4 _MainTex_TexelSize;

            float4 _OuterGlowColor;
			float _GlowFactor;

            struct appdata
            {
				float4 vertex : POSITION;
				fixed4 color : COLOR;
				float2 texcoord : TEXCOORD0;
				float2 texcoord1 : TEXCOORD1;	
            };

            struct v2f
            {
				float4 vertex : SV_POSITION;
				fixed4 color : COLOR;
				float2 texcoord : TEXCOORD0;
				float2 texcoord1 : TEXCOORD1;
            };

            v2f vert(appdata IN)
            {
                v2f o;

				o.vertex = UnityObjectToClipPos(IN.vertex);
                o.texcoord = IN.texcoord;
			    o.texcoord1 = IN.texcoord1;

                o.color = IN.color * _Color;

                return o;
            }

            fixed4 frag(v2f IN) : SV_Target
            {
                fixed4 color;
				if(IN.texcoord1.x > 0.9f)	  // 边缘
				{
					color = IN.color;
					float dis = length(IN.texcoord);
					color.a = 1-(dis * _GlowFactor * 2.0f);
				}
				else
				{
					color = (tex2D(_MainTex, IN.texcoord) + _TextureSampleAdd) * IN.color;
				}
				color.a *= IN.color.a;		// 需要自己的a通道

				// 单pass透明add
				color.rgb = color.rgb * color.a;
				if (IN.texcoord1.x < 0.1f)
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