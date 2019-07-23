using UnityEngine;


public class DepthTextureCamera : MonoBehaviour
{
    public int m_lightIndex;
    private Light m_light;
    private Camera m_camera;
    private RenderTexture m_rt;

    void Start()
    {
        m_light = GetComponent<Light>();
        // 如果深度图的分辨率比较低，那么很多个像素会取到同一个深度图上的点
        m_rt = new RenderTexture(1024, 1024, 0);
        m_rt.wrapMode = TextureWrapMode.Clamp;

        m_camera = new GameObject().AddComponent<Camera>();
        m_camera.name = "DepthCamera";
        m_camera.depth = -1;
        m_camera.backgroundColor = Color.white;
        m_camera.clearFlags = CameraClearFlags.Color; ;
        
        if(m_light.type == LightType.Directional)
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
    }

    void Update()
    {
        m_camera.Render();
        // GL.GetGPUProjectionMatrix写法兼容dx和gl的投影转换
        Matrix4x4 tm = GL.GetGPUProjectionMatrix(m_camera.projectionMatrix, false);
        //【世界空间】变换【摄像机空间】矩阵 右乘 【摄像机空间】变换【摄像机投影空间】矩阵
        // 结果为：【世界空间】变换【摄像机投影空间】矩阵
        tm = tm * m_camera.worldToCameraMatrix;

        Shader.SetGlobalMatrix("_WorldToProjectionMatrix", tm);
        Shader.SetGlobalTexture("_DepthTexture", m_rt);
    }


}
