Shader "DeapthTextureShader"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "RenderType" = "Opaque" }

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 depth : TEXCOORD1;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			v2f vert(appdata v)
			{
				v2f o;
				// 模型空间变换到裁剪空间，值越是【-1,1】
				o.pos = UnityObjectToClipPos(v.vertex);
				// 记录裁剪空间中的z,w分量
				o.depth = o.pos.zw;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				// 归一化设备坐标NDC时，手动操作齐次除法，可以得到深度值
				float depth = i.depth.x / i.depth.y;
				// depth时的点，值域已经是【0,1】了，因为负数的点在已经被裁剪掉了
				// 将一个Float值存储在float4值当中，在frag函数中这个float4被当做颜色最终输出
				// 编码输入，解码输出值域都是【0,1】，提高深度值的精度
				fixed4 col = EncodeFloatRGBA(depth);
				return col;
			}
			ENDCG
		}
	}
}
