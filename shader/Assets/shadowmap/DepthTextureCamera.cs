using UnityEngine;


public class DepthTextureCamera : MonoBehaviour
{
    private Light m_light;
    private Camera m_camera;
    private RenderTexture m_rt;

    public Vector2 m_textSize = new Vector2(256, 256);
    /// <summary>
    /// 矫正矩阵
    /// </summary>
    //private Matrix4x4 sm = new Matrix4x4();

    void Start()
    {
        m_light = GetComponent<Light>();
        // 如果深度图的分辨率比较低，那么很多个像素会取到同一个深度图上的点
        m_rt = new RenderTexture((int)m_textSize.x, (int)m_textSize.y, 0);
        m_rt.wrapMode = TextureWrapMode.Clamp;

        m_camera = new GameObject().AddComponent<Camera>();
        m_camera.name = "DepthCamera";
        m_camera.depth = -1;
        m_camera.backgroundColor = Color.white;
        m_camera.clearFlags = CameraClearFlags.Color;

        if (m_light.type == LightType.Directional)
        {
            m_camera.orthographic = true;
        }
        else
        {
            m_camera.orthographic = false;
        }

        m_camera.orthographicSize = 10;
        m_camera.farClipPlane = 50;
        m_camera.targetTexture = m_rt;
        // _camera渲染时 将带有RenderType标签的shader替换为DeapthTextureShader
        m_camera.SetReplacementShader(Shader.Find("DeapthTextureShader"), "RenderType");
        m_camera.transform.SetParent(transform);
        m_camera.transform.localPosition = Vector3.zero;
        m_camera.transform.localRotation = Quaternion.identity;
        m_camera.enabled = false;

        //sm.m00 = 0.5f;
        //sm.m11 = 0.5f;
        //sm.m22 = 0.5f;
        //sm.m03 = 0.5f;
        //sm.m13 = 0.5f;
        //sm.m23 = 0.5f;
        //sm.m33 = 1;
    }

    void Update()
    {
        m_camera.Render();
        // GL.GetGPUProjectionMatrix写法兼容dx和gl的投影转换
        Matrix4x4 tm = GL.GetGPUProjectionMatrix(m_camera.projectionMatrix, false);
        //【世界空间】变换【摄像机空间】矩阵 右乘 【摄像机空间】变换【摄像机投影空间】矩阵
        // 结果为：【世界空间】变换【摄像机投影空间】矩阵
        tm = tm * m_camera.worldToCameraMatrix;
        //tm = sm * tm;

        Shader.SetGlobalMatrix("_WorldToProjectionMatrix", tm);
        Shader.SetGlobalTexture("_DepthTexture", m_rt);
        Shader.SetGlobalInt("_TexelWidth", (int)m_textSize.x);
        Shader.SetGlobalInt("_TexelHight", (int)m_textSize.y);
    }


}
