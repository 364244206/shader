using UnityEngine;
using System.Collections;

public class GaussianBlur : PostEffectsBase {

	public Shader gaussianBlurShader;
	private Material gaussianBlurMaterial = null;

	public Material material {  
		get {
			gaussianBlurMaterial = CheckShaderAndCreateMaterial(gaussianBlurShader, gaussianBlurMaterial);
			return gaussianBlurMaterial;
		}  
	}

	// Blur iterations - larger number means more blur.
	[Range(0, 4)]
	public int iterations = 3;   // 模糊迭代，数值越大，迭代越多
	
	// Blur spread for each iteration - larger value means more blur
	[Range(0.2f, 3.0f)]
	public float blurSpread = 0.6f;  // 每次迭代的扩展程度
	
	[Range(1, 8)]
	public int downSample = 2;   // rt的缩放比例，越大，像素感越强
	
	/// 1st edition: just apply blur
//	void OnRenderImage(RenderTexture src, RenderTexture dest) {
//		if (material != null) {
//			int rtW = src.width;
//			int rtH = src.height;
//			RenderTexture buffer = RenderTexture.GetTemporary(rtW, rtH, 0);
//
//			// Render the vertical pass
//			Graphics.Blit(src, buffer, material, 0);
//			// Render the horizontal pass
//			Graphics.Blit(buffer, dest, material, 1);
//
//			RenderTexture.ReleaseTemporary(buffer);
//		} else {
//			Graphics.Blit(src, dest);
//		}
//	} 

	/// 2nd edition: scale the render texture
//	void OnRenderImage (RenderTexture src, RenderTexture dest) {
//		if (material != null) {
//			int rtW = src.width/downSample;
//			int rtH = src.height/downSample;
//			RenderTexture buffer = RenderTexture.GetTemporary(rtW, rtH, 0);
//			buffer.filterMode = FilterMode.Bilinear;
//
//			// Render the vertical pass
//			Graphics.Blit(src, buffer, material, 0);
//			// Render the horizontal pass
//			Graphics.Blit(buffer, dest, material, 1);
//
//			RenderTexture.ReleaseTemporary(buffer);
//		} else {
//			Graphics.Blit(src, dest);
//		}
//	}

	/// 3rd edition: use iterations for larger blur
	void OnRenderImage (RenderTexture src, RenderTexture dest) {
		if (material != null) {
			int rtW = src.width/downSample;
			int rtH = src.height/downSample;

            // 构建缓冲区0
			RenderTexture buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0);
            // 设置滤波模式为双线性
			buffer0.filterMode = FilterMode.Bilinear;

            // 将屏幕纹理渲染到buffer0
            Graphics.Blit(src, buffer0);

			for (int i = 0; i < iterations; i++) {
				material.SetFloat("_BlurSize", 1.0f + i * blurSpread);

                // 构建缓冲区1
				RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

                // 渲染垂直pass的结果到buffer1
                // Render the vertical pass
                Graphics.Blit(buffer0, buffer1, material, 0);
                // 释放缓冲区0
				RenderTexture.ReleaseTemporary(buffer0);
				buffer0 = buffer1;
				buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

                // 渲染水平pass的结果到buffer1
                // Render the horizontal pass
                Graphics.Blit(buffer0, buffer1, material, 1);
                // 释放缓冲区0
				RenderTexture.ReleaseTemporary(buffer0);
				buffer0 = buffer1;
			}

			Graphics.Blit(buffer0, dest);
			RenderTexture.ReleaseTemporary(buffer0);
		} else {
			Graphics.Blit(src, dest);
		}
	}
}
