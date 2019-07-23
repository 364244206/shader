using UnityEngine;


public class DepthTextureCamera : MonoBehaviour
{
    Camera _camera;

    RenderTexture _rt;
    /// <summary>
    /// 光照的角度
    /// </summary>
    public Transform lightTrans;

    void Start()
    {
        _camera = new GameObject().AddComponent<Camera>();
        _camera.name = "DepthCamera";
        _camera.depth = 2;
        _camera.clearFlags = CameraClearFlags.SolidColor;
        _camera.backgroundColor = new Color(1, 1, 1, 0);

        _camera.aspect = 1;
        _camera.transform.position = transform.position;
        _camera.transform.rotation = transform.rotation;
        _camera.transform.parent = transform;

        _camera.orthographic = true;
        _camera.orthographicSize = 10;
        _camera.farClipPlane = 10;

        _rt = new RenderTexture(1024, 1024, 0);
        _rt.wrapMode = TextureWrapMode.Clamp;
        _camera.targetTexture = _rt;
        // _camera渲染时 将带有RenderType标签的shader替换为DeapthTextureShader
        _camera.SetReplacementShader(Shader.Find("DeapthTextureShader"), "RenderType");
    }

    void Update()
    {
        _camera.Render();
        // GL.GetGPUProjectionMatrix写法兼容dx和gl的投影转换
        Matrix4x4 tm = GL.GetGPUProjectionMatrix(_camera.projectionMatrix, false);
        //【世界空间】变换【摄像机空间】矩阵 右乘 【摄像机空间】变换【摄像机投影空间】矩阵
        // 结果为：【世界空间】变换【摄像机投影空间】矩阵
        tm = tm * _camera.worldToCameraMatrix;

        Shader.SetGlobalMatrix("_WorldToProjectionMatrix", tm);
        Shader.SetGlobalTexture("_DepthTexture", _rt);
    }


}
