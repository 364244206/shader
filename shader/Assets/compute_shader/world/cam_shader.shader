﻿Shader "Custom/Fow" {
	Properties{
		_MainTex("Base", 2D) = "white"{}
	}

		SubShader{
			Pass{
				ZTest Always
				Cull Off
				ZWrite Off
				Fog{Mode off}

				CGPROGRAM
				#pragma vertex vert_img
				#pragma fragment frag vertex:vert
				#pragma fragmentoption ARB_precision_hint_fastest  // 使用低精度，提升效率
				#include "UnityCG.cginc"

				sampler2D _MainTex;

	float4 _worldToUv;

				sampler2D _tex;
	
				sampler2D _CameraDepthTexture; // 系统保存的场景深度

				uniform float4x4 _InverseMVP;  // 屏幕坐标转世界坐标
		
				uniform float4 _camPos;        // 摄像机位置
			
				uniform float4 _pos;        // 玩家位置
				struct Input
				{
					float4 position : POSITION;
					float2 uv : TEXCOORD0;
				};

				void vert(inout appdata_full v, out Input o)
				{
					o.position = mul(UNITY_MATRIX_MVP, v.vertex);
					o.uv = v.texcoord.xy;
				}

				// 摄像机投影坐标转世界坐标
				float3 CamToWorld(in float2 uv, in float depth)
				{
					float4 pos = float4(uv.x, uv.y, depth, 1.0);
					// 坐标系转换，屏幕-世界，0,0由左下转到中间
					pos.xyz = pos.xyz * 2.0 - 1.0;
					// 屏幕坐标 转 世界坐标
					pos = mul(_InverseMVP, pos);
					return pos.xyz / pos.w;
				}

				fixed4 frag(Input i) :COLOR
				{
					half4 original = tex2D(_MainTex, i.uv);

				#if SHADER_API_D3D9
					// 翻转Y轴
					i.uv.y = 1.0 - i.uv.y;
					// 通过UV坐标，对深度图进行采样
					// 通过UNITY_SAMPLE_DEPTH转换为深度
					// 通过uv和深度，计算出世界坐标的位置
					float depth = UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, i.uv));
					float3 pos = CamToWorld(i.uv, depth);
				#else
					float depth = UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, i.uv));
					float3 pos = CamToWorld(i.uv, depth);
				#endif

					// 战争迷雾在海平面上
					if (pos.y < 0.0)
					{
						// 当前点到摄像机的单位向量
						float3 dir = normalize(pos - _camPos.xyz);
						// 计算平面和射线的交点
						pos = _camPos.xyz - dir * (_camPos.y / dir.y);
					}
					// 位置转到tex的中间
					//float center = 512 * 0.5f;
					//pos += float3(center, 0, center);
					pos -= _pos;
					// 将世界坐标的X，Z轴转换为值域为[0-1]的值，用于映射到屏幕空间
					float2 uv = pos.xz * _worldToUv;
			
					// 刚进入的和当前可见的纹理融合
					half4 fog = tex2D(_tex, uv);
					// 屏幕色X黑色的叠加色 与 屏幕色 的插值
					fixed4 col = lerp(original * fixed4(0, 0, 0, 0.5), original, 1 - fog.r);
					return col;
				}
				ENDCG
			}
	}
		FallBack off
}