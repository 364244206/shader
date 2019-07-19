
// 玻璃效果：高光，凹凸，反射，折射

Shader "Unity Shaders Book/Chapter 10/Glass Refraction" {
	Properties {
		_MainTex ("Main Tex", 2D) = "white" {}
		_BumpMap ("Normal Map", 2D) = "bump" {}
		_Cubemap ("Environment Cubemap", Cube) = "_Skybox" {}
		_Distortion ("Distortion", Range(0, 100)) = 10
		_RefractAmount ("Refract Amount", Range(0.0, 1.0)) = 1.0

		_Specular("Specular", Color) = (1, 1, 1, 1)
		_Gloss("Gloss", Range(1.0, 256)) = 20
				_FresnelScale("Fresnel Scale", Range(0, 1)) = 0.5
	}
	SubShader {
		// 制定渲染队列为半透明 
		Tags { "Queue"="Transparent" "RenderType"="Opaque" }
		
		// 对当前对象后面的屏幕抓取图像到_RefractionTex，在下一个pass中可以使用_RefractionTex
		GrabPass { "_RefractionTex" }
		
		Pass {		
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;

			sampler2D _BumpMap;
			float4 _BumpMap_ST;

			samplerCUBE _Cubemap;			 // 模拟反射的环境纹理

			float _Distortion;				 // 控制模拟折射时图像的扭曲程度

			fixed _RefractAmount;			 // 用于控制反射，折射程度

			sampler2D _RefractionTex;		 // 折射纹理
			float4 _RefractionTex_TexelSize; // 折射纹理尺寸
			
			fixed4 _Specular;
			float _Gloss;
			fixed _FresnelScale;

			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT; 
				float2 texcoord: TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float4 scrPos : TEXCOORD0;
				float4 uv : TEXCOORD1;

				float4 TtoW0 : TEXCOORD2;  
			    float4 TtoW1 : TEXCOORD3;  
			    float4 TtoW2 : TEXCOORD4; 
			};
			
			v2f vert (a2v v) {
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				// 计算当前模型顶点在屏幕坐标中的纹理坐标
				// scrPos要除以分量w才是最终的屏幕坐标，但是因为顶点到片元有一个差值的过程
				// 投影空间中不是线性的，除以w后坐标会不准确，所以在片元中再除以w结果才是正确的
				o.scrPos = ComputeGrabScreenPos(o.pos);

				o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);

				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;

				// 世界空间中的三个单位坐标轴TBN，按照列摆放的变换矩阵
				// 可以将方向从【切线空间】变换到【世界空间】
				// 为了充分利用插值寄存器的存储空间，把顶点位置放到w分量存储
				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target {	
				// 获取世界空间中像素点的位置
				float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
				// 获取世界空间中灯光方向，摄像机的方向
				fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));

				// 获取在【切线空间】的法线方向
				fixed3 bumpDir = UnpackNormal(tex2D(_BumpMap, i.uv.zw));

				// 使用法线信息乘以扭曲系数和折射纹理，对屏幕图像的采样坐标进行偏移
				float2 offset = bumpDir.xy * _Distortion * _RefractionTex_TexelSize.xy;
				// _Distortion值越大，偏移量越大，扭曲程度越大
				// 在切线空间进行偏移是因为能反应顶点局部空间下的法线方向，不会扭曲的很离谱？
				i.scrPos.xy = i.scrPos.xy + i.scrPos.z * offset;
				// 对投影空间中的纹理坐标进行透视除法得到真正的屏幕坐标
				fixed3 refrCol = tex2D(_RefractionTex, i.scrPos.xy / i.scrPos.w).rgb;

				// 将法线方向从切线空间 变换 到世界空间
				// 矩阵的乘法如下(行列相乘相加)：
				// Tx,Bx,Nx   Px   Tx*Px + Bx*Py + Nx*Pz
				// Ty,By,Ny * Py = Ty*Px + By*Py + Ny*Pz
				// Tz,Bz,Nz   Pz   Tz*Px + Bz*Py + Nz*Pz
				bumpDir = normalize(half3(
					dot(i.TtoW0.xyz, bumpDir), 
					dot(i.TtoW1.xyz, bumpDir), 
					dot(i.TtoW2.xyz, bumpDir)));
				// 获取反射方向
				fixed3 reflDir = reflect(-viewDir, bumpDir);

				// 贴图颜色
				fixed4 texColor = tex2D(_MainTex, i.uv.xy);
				// 漫反射，高光
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * texColor;
				fixed3 diffuse = _LightColor0.rgb * texColor * max(0, dot(bumpDir, lightDir));
				fixed3 halfDir = normalize(lightDir + viewDir);
				fixed3 specular = _LightColor0.rgb * _Specular * pow(max(0, dot(bumpDir, halfDir)), _Gloss);
				fixed3 lightCol = ambient + diffuse + specular;

				// 菲利尔根据视觉方向改变反射效果
				// 位置越远，角度越小的地方反射越明显（如近处水面透明，远处水面倒影明显）
				// 菲利尔公式 = 反射系数+(1-反射系数)*pow(1-v·n,5);
				fixed fresnel = _FresnelScale + (1 - _FresnelScale) * pow(1 - dot(viewDir, bumpDir), 5);

				// 反射颜色，使用反射方向对cubemap采样，然后叠加光照颜色
				fixed3 reflCol = lerp(texCUBE(_Cubemap, reflDir).rgb ,lightCol , fresnel);


				// 融合反射颜色和折射颜色
				fixed3 finalColor = reflCol * (1 - _RefractAmount) + refrCol * _RefractAmount;

				return fixed4(finalColor, 1);
			}
			ENDCG
		}
	}
	
	FallBack "Diffuse"
}
