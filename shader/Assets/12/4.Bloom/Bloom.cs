using UnityEngine;
using System.Collections;

public class Bloom : PostEffectsBase {

	public Shader bloomShader;
	private Material bloomMaterial = null;
	public Material material {  
		get {
			bloomMaterial = CheckShaderAndCreateMaterial(bloomShader, bloomMaterial);
			return bloomMaterial;
		}  
	}

	// Blur iterations - larger number means more blur.
	[Range(0, 4)]
	public int iterations = 3;         // 模糊迭代，数值越大，模糊效果越明显
	
	// Blur spread for each iteration - larger value means more blur
	[Range(0.2f, 3.0f)]
	public float blurSpread = 0.6f;       // 模糊扩散，值越大，模糊范围会变大

	[Range(1, 8)]
	public int downSample = 2;           // 低采样，rt的缩放比例，越大，像素感越强

    [Range(0.0f, 4.0f)]
	public float luminanceThreshold = 0.6f;  // 亮度阈值，一般情况亮度值不会超过1，如果开启HDR可以大于1

	void OnRenderImage (RenderTexture src, RenderTexture dest) {
		if (material != null) {
			material.SetFloat("_LuminanceThreshold", luminanceThreshold);

			int rtW = src.width/downSample;
			int rtH = src.height/downSample;
			
			RenderTexture buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0);
			buffer0.filterMode = FilterMode.Bilinear;
            // 通过第一个pass提取图像中比较亮的区域，并且存储在buffer0中
            Graphics.Blit(src, buffer0, material, 0);
			// 然后进行和高斯模糊一样的高斯模糊迭代处理
			for (int i = 0; i < iterations; i++) {
				material.SetFloat("_BlurSize", 1.0f + i * blurSpread);
				
				RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);
				
				// Render the vertical pass
				Graphics.Blit(buffer0, buffer1, material, 1);
				
				RenderTexture.ReleaseTemporary(buffer0);
				buffer0 = buffer1;
				buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);
				
				// Render the horizontal pass
				Graphics.Blit(buffer0, buffer1, material, 2);
				
				RenderTexture.ReleaseTemporary(buffer0);
				buffer0 = buffer1;
			}
            // 经过高斯模糊迭代处理后得到buffer0
            // 再把纹理buffer0传递给_Bloom纹理属性，并调用第四个pass进行混合
            material.SetTexture ("_Bloom", buffer0);  
			Graphics.Blit (src, dest, material, 3);  

			RenderTexture.ReleaseTemporary(buffer0);
		} else {
			Graphics.Blit(src, dest);
		}
	}
}
