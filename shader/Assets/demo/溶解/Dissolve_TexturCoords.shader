Shader "Dissolve/Dissolve_TexturCoords" {
	Properties{
		_Color("主颜色", Color) = (1,1,1,1)                       // 主色  
		_MainTex("模型贴图", 2D) = "white" {}                      // 主材质  
		_DissolveText("溶解贴图", 2D) = "white" {}                 // 溶解贴图  
		_Tile("溶解贴图的平铺大小", Range(0, 1)) = 1                // 平铺值,设置溶解贴图大小  

		_Amount("溶解值", Range(0, 1)) = 0.5                     // 溶解度  
		_DissSize("溶解大小", Range(0, 1)) = 0.1                   // 溶解范围大小  

		_DissColor("溶解主色", Color) = (1,1,1,1)                  // 溶解颜色  
		_AddColor("叠加色，与主色叠加为开始色[R|G|B>0表示启用]", Color) = (1,1,1,1) // 改色与溶解色融合形成开始色  
	}
		SubShader{
			Tags { "RenderType" = "Opaque" }
			LOD 200
			Cull off

			CGPROGRAM
			#pragma target 3.0  
			#pragma surface surf BlinnPhong  

			sampler2D _MainTex;
			sampler2D _DissolveText;
			fixed4 _Color;          // 主色  
			half _Tile;             // 平铺值  
			half _Amount;           // 溶解度  
			half _DissSize;         // 溶解范围  
			half4 _DissColor;       // 溶解颜色  
			half4 _AddColor;        // 叠加色  
			// 最终色  
			static half3 finalColor = float3(1,1,1);

			struct Input {
				float2 uv_MainTex;  // 只需要主材质的UV信息  
			};

			void surf(Input IN, inout SurfaceOutput o) {
				// 对主材质进行采样  
				fixed4 tex = tex2D(_MainTex, IN.uv_MainTex);
				// 设置主材质和颜色  
				o.Albedo = tex.rgb * _Color.rgb;
				// 对裁剪材质进行采样，取R色值  
				float ClipTex = tex2D(_DissolveText, IN.uv_MainTex / _Tile).r;

				// 裁剪量 = 裁剪材质R - 外部设置量  
				float ClipAmount = ClipTex - _Amount;
				// 溶解值为0时，不计算溶解效果
				//if (_Amount > 0)
				//{
					// 如果裁剪材质的R色值 < 设置的裁剪值  那么此点将被裁剪  
					//if (ClipAmount < 0)
					//{
					//	clip(-0.1);
					//}
					//// 然后处理没有被裁剪的值  
					//else
					//{
						// 针对没有被裁剪的点，【裁剪量】小于【裁剪大小】的做处理  
						// 如果设置了叠加色，那么该色为ClipAmount/_DissSize(这样会形成渐变效果)  
						if (ClipAmount < _DissSize)   // 溶解贴图的r值 < 溶解大小值时
						{
							if (_AddColor.x == 0)
								finalColor.x = _DissColor.x;
							else
								finalColor.x = ClipAmount / _DissSize;

							if (_AddColor.y == 0)
								finalColor.y = _DissColor.y;
							else
								finalColor.y = ClipAmount / _DissSize;

							if (_AddColor.z == 0)
								finalColor.z = _DissColor.z;
							else
								finalColor.z = ClipAmount / _DissSize;
							// 融合  
							o.Albedo = o.Albedo * finalColor * 2;
						}
					//}
				//}
				o.Alpha = tex.a * _Color.a;
			}
			ENDCG
		}//endsubshader  
}