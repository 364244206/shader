Shader "Custom/my1"
{
	Properties{
	   _Color("Main Color", Color) = (1,1,1,1)
	   _MainTex("Base (RGB) Trans (A)", 2D) = "white" {}
	   _SizeX("列", Float) = 4

	   _SizeY("行", Float) = 2
	   _Speed("播放速度", Float) = 150
	}

		SubShader{
		   // 这里使用Unity3d自带光照模型Lambert
		   // 不用做顶点处理，只需要一个表面处理函数surf
		   CGPROGRAM
		   #pragma surface surf Lambert alpha

		   // 声明参数
		   fixed4 _Color;
		   sampler2D _MainTex;
		   uniform fixed _SizeX;
		   uniform fixed _SizeY;
		   uniform fixed _Speed;
		   // 获取_MainTex的UV信息定义输入结构体
		   struct Input {
			   // 在贴图变量前加上uv表示提取uv值(二维坐标)
				  float2 uv_MainTex;
			  };

			  void surf(Input IN, inout SurfaceOutput o) {
				  // 获取单元格UV
					float2 cellUV = float2(IN.uv_MainTex.x / _SizeX, IN.uv_MainTex.y / _SizeY);
					 // UV坐标值范围为0-1，获取单元格宽度
				  float deltaX = 1 / _SizeX; // 单元格增量宽度
				  float deltaY = 1 / _SizeY; // 单元格增量高度

				  // 当前播放总索引
				  int index = _Time.y * _Speed;
				  // 求列索引
					 int col = fmod(index, _SizeX);
					 // 求行索引
					 int row = index / _SizeX;
					 // 原始UV + 当前格增量
					 cellUV.x += col * deltaX;
					 cellUV.y -= row * deltaY;
					 // 创建tex2d(材质，uv)*主色
					 fixed4 c = tex2D(_MainTex, cellUV) * _Color;
					 // RGB
					 o.Albedo = c.rgb;
					 // 透明度
					 o.Alpha = c.a;
				 }
				 ENDCG
	   }
}