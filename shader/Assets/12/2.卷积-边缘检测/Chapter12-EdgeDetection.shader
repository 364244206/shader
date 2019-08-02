Shader "Unity Shaders Book/Chapter 12/Edge Detection" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_EdgeOnly ("Edge Only", Float) = 1.0
		_EdgeColor ("Edge Color", Color) = (0, 0, 0, 1)
		_BackgroundColor ("Background Color", Color) = (1, 1, 1, 1)
	}
	SubShader {
		Pass {  
			ZTest Always Cull Off ZWrite Off
			
			CGPROGRAM
			
			#include "UnityCG.cginc"
			
			#pragma vertex vert  
			#pragma fragment fragSobel
			
			sampler2D _MainTex;  
			uniform half4 _MainTex_TexelSize;
			fixed _EdgeOnly;
			fixed4 _EdgeColor;
			fixed4 _BackgroundColor;
			
			struct v2f {
				float4 pos : SV_POSITION;
				half2 uv[9] : TEXCOORD0;
			};
			  
			v2f vert(appdata_img v) {
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				
				half2 uv = v.texcoord;
				// 取每个点的邻接点的纹理坐标信息
				// 在顶点着色器处理，提高效率。从顶点到片元的插值是线性的，并不会影响计算结果。
				o.uv[0] = uv + _MainTex_TexelSize.xy * half2(-1, -1);
				o.uv[1] = uv + _MainTex_TexelSize.xy * half2(0, -1);
				o.uv[2] = uv + _MainTex_TexelSize.xy * half2(1, -1);
				o.uv[3] = uv + _MainTex_TexelSize.xy * half2(-1, 0);
				o.uv[4] = uv + _MainTex_TexelSize.xy * half2(0, 0);
				o.uv[5] = uv + _MainTex_TexelSize.xy * half2(1, 0);
				o.uv[6] = uv + _MainTex_TexelSize.xy * half2(-1, 1);
				o.uv[7] = uv + _MainTex_TexelSize.xy * half2(0, 1);
				o.uv[8] = uv + _MainTex_TexelSize.xy * half2(1, 1);
				return o;
			}
			
			fixed luminance(fixed4 color) {
				return  0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b; 
			}
			
			// 边缘检测算子Sobel,获取梯度值
			half Sobel(v2f i) {
				// 卷积核（矩阵过滤器）,构造3x3垂直边缘过滤器矩阵
				// 卷积结果：每一个点的邻接点元素与过滤器对应的元素相乘并累加
				// 此时的值越大说明越是接近边缘
				// 如果是原图有垂直的边缘，那么可以形成一条垂直的线条
				// x,y方向上值
				const half Gy[9] = {-1,  0,  1,
										-2,  0,  2,
										-1,  0,  1};
				const half Gx[9] = {-1, -2, -1,
										0,  0,  0,
										1,  2,  1};		
				
				half texColor;
				half edgeX = 0;
				half edgeY = 0;
				for (int it = 0; it < 9; it++) {
					texColor = luminance(tex2D(_MainTex, i.uv[it]));
					edgeX += texColor * Gx[it];
					edgeY += texColor * Gy[it];
				}

				// 梯度值应该等于sqrt(x平方 + y平方)
				//half edge = 1 - sqrt((edgeX * edgeX) + (edgeY * edgeY));
				// 为了效率考虑，直接采用绝对值的方式，为了方便下面使用lerp函数，所以用1-
				half edge = 1 - (abs(edgeX) + abs(edgeY));
				return edge;
			}
			
			fixed4 fragSobel(v2f i) : SV_Target {
				// 当前像素的梯度值,值越小表示越可能是一个边缘点
				half edge = Sobel(i);
				fixed4 col = tex2D(_MainTex, i.uv[4]);
				fixed4 withEdgeColor = lerp(_EdgeColor, col, edge);
				//fixed4 onlyEdgeColor = lerp(_EdgeColor, _BackgroundColor, edge);
				//return lerp(withEdgeColor, onlyEdgeColor, _EdgeOnly);
				// 稍微改改，可以设置边缘线的强度
				return lerp(withEdgeColor, col, _EdgeOnly);
 			}
			
			ENDCG
		} 
	}
	FallBack Off
}
