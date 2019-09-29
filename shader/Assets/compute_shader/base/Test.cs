using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

// 画圆，熟悉UV等
public class Test : MonoBehaviour
{
    public Texture2D inputTexture;
    public RawImage outputImage;
    public ComputeShader shader;

    void Start()
    {
        RenderTexture t = new RenderTexture(inputTexture.width, inputTexture.height, 24);
        t.enableRandomWrite = true;
        t.Create();
        outputImage.texture = t;

        int k = shader.FindKernel("CSMain");
        shader.SetTexture(k, "inputTexture", inputTexture);
        shader.SetTexture(k, "outputTexture", t);
        shader.Dispatch(k, 32, 32, 1);
    }
}