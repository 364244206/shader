using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class RunComputeShader : MonoBehaviour
{
    public ComputeShader m_Shader;
    private RenderTexture m_Texture;

    private int m_NumThreadsGroupsX, m_NumThreadsGroupsY, m_NumThreadsGroupsZ = 1;

    void Start()
    {
        UpdateSize();
    }

    private void UpdateSize()
    {
        int width = Screen.width;
        int height = Screen.height;

        if (m_Texture != null && m_Texture.width == width && m_Texture.height == height)
        {
            return;
        }
        if (m_Texture != null)
        {
            m_Texture.Release();
        }

        m_Texture = new RenderTexture(width, height, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);
        m_Texture.filterMode = FilterMode.Point;
        m_Texture.enableRandomWrite = true;
        m_Texture.Create();

        RawImage rawImage = GetComponent<RawImage>();
        rawImage.rectTransform.anchorMin = Vector2.zero;
        rawImage.rectTransform.anchorMax = Vector2.one;
        rawImage.rectTransform.sizeDelta = Vector2.zero;
        rawImage.texture = m_Texture;

        // 内核线程数 * 线程组 = 图片尺寸
        uint numThreadsX, numThreadsY, numThreadsZ;
        m_Shader.GetKernelThreadGroupSizes(0, out numThreadsX, out numThreadsY, out numThreadsZ);
        m_NumThreadsGroupsX = (int)(m_Texture.width / numThreadsX);
        m_NumThreadsGroupsY = (int)(m_Texture.height / numThreadsY);

        m_Shader.SetTexture(0, "Result", m_Texture);
        m_Shader.SetVector("iResolution", new Vector4(width, height));
    }

    // Update is called once per frame
    void Update()
    {
        UpdateSize();
        m_Shader.SetFloat("iGlobalTime", Time.time);
        m_Shader.Dispatch(0, m_NumThreadsGroupsX, m_NumThreadsGroupsY, m_NumThreadsGroupsZ);
    }
}
