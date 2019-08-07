
//运动模糊
//1.混合多张屏幕图像来模拟运动模糊效果。
//2.使用速度映射图。图中存储每个像素的速度，然后控制模糊方向和大小，但是要修改场景所有物体的shader
//3.NDC空间计算速度差值。计算每个像素在世界空间下的位置，使用深度图，投影矩阵等反推得到前一帧在NDC中的坐标，
//  然后和当前帧在NDC中的坐标求差值，得到速度向量，缺点是在片元计算两次矩阵乘法

Shader "Unity Shaders Book/Chapter 13/Motion Blur With Depth Texture" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_BlurSize ("Blur Size", Float) = 1.0
	}
	SubShader {
		CGINCLUDE
		
		#include "UnityCG.cginc"
		
		sampler2D _MainTex;
		half4 _MainTex_TexelSize;
		// unity传给我们的深度纹理
		sampler2D _CameraDepthTexture;
		// 世界转投影矩阵的逆矩阵
		float4x4 _CurrentViewProjectionInverseMatrix;
		float4x4 _PreviousViewProjectionMatrix;
		half _BlurSize;
		
		struct v2f {
			float4 pos : SV_POSITION;
			half2 uv : TEXCOORD0;
			half2 uv_depth : TEXCOORD1;
		};
		
		v2f vert(appdata_img v) {
			v2f o;
			o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
			
			o.uv = v.texcoord;
			o.uv_depth = v.texcoord;
			
			#if UNITY_UV_STARTS_AT_TOP
			// 对深度纹理的采样坐标进行了平台差异化处理
			if (_MainTex_TexelSize.y < 0)
				o.uv_depth.y = 1 - o.uv_depth.y;
			#endif
					 
			return o;
		}
		
		fixed4 frag(v2f i) : SV_Target {
			// 对深度纹理进行采样，得到深度值z，值域为【0,1】
			float d = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth);
			// 得到投影空间得NDC下的坐标，将其x,y,z映射到【-1,1】
			float4 H = float4(i.uv.x * 2 - 1, i.uv.y * 2 - 1, d * 2 - 1, 1);
			// 将投影空间下的值，转到世界坐标
			float4 D = mul(_CurrentViewProjectionInverseMatrix, H);
			// 除以w分量得到世界坐标位置
			float4 worldPos = D / D.w;
			
			float4 currentPos = H;
			// 得到前一帧在投影空间的坐标值，值域变换到【-1,1】
			float4 previousPos = mul(_PreviousViewProjectionMatrix, worldPos);
			previousPos /= previousPos.w;

			// 使用前一帧和当前帧再屏幕下的位置差，得到像素的移动向量
			float2 velocity = (currentPos.xy - previousPos.xy)/2.0f;
			
			
			float2 uv = i.uv;
			float4 c = tex2D(_MainTex, uv);
			// 对当前像素点，操作3次，取之前的位置对应的颜色值，并且叠加求平均值
			// 通过_BlurSize能控制距离
			uv += velocity * _BlurSize;
			for (int it = 1; it < 3; it++, uv += velocity * _BlurSize) {
				float4 currentColor = tex2D(_MainTex, uv);
				c += currentColor;
			}
			c /= 3;
			
			return fixed4(c.rgb, 1.0);
		}
		
		ENDCG
		
		Pass {      
			ZTest Always Cull Off ZWrite Off
			    	
			CGPROGRAM  
			
			#pragma vertex vert  
			#pragma fragment frag  
			  
			ENDCG  
		}
	} 
	FallBack Off
}
