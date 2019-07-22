using UnityEngine;
using System.Collections;

    /// <summary>
    /// 创建depth相机
    /// by lijia
    /// </summary>
    public class DepthTextureCamera : MonoBehaviour
    {
        Camera _camera;

        RenderTexture _rt;
        /// <summary>
        /// 光照的角度
        /// </summary>
        public Transform lightTrans;

        Matrix4x4 sm = new Matrix4x4();

        void Start()
        {
            _camera = new GameObject().AddComponent<Camera>();
            _camera.name = "DepthCamera";
            _camera.depth = 2;
            _camera.clearFlags = CameraClearFlags.SolidColor;
            _camera.backgroundColor = new Color(1, 1, 1, 0);

            //_camera.cullingMask = LayerMask.GetMask("Player");
            _camera.aspect = 1;
            _camera.transform.position = this.transform.position;
            _camera.transform.rotation = this.transform.rotation;
            _camera.transform.parent = this.transform;

            _camera.orthographic = true;
            _camera.orthographicSize = 10;

            sm.m00 = 0.5f;
            sm.m11 = 0.5f;
            sm.m22 = 0.5f;
            sm.m03 = 0.5f;
            sm.m13 = 0.5f;
            sm.m23 = 0.5f;
            sm.m33 = 1;

            _rt = new RenderTexture(1024, 1024, 0);
            _rt.wrapMode = TextureWrapMode.Clamp;
            _camera.targetTexture = _rt;
            _camera.SetReplacementShader(Shader.Find("lijia/DeapthTextureShader"), "RenderType");
        }

        void Update()
        {
            //this.transform.eulerAngles = new Vector3(37.2f, -46.109f, -90.489f);
            _camera.Render();
            Matrix4x4 tm = GL.GetGPUProjectionMatrix(_camera.projectionMatrix, false) * _camera.worldToCameraMatrix;

            tm = sm * tm;

            Shader.SetGlobalMatrix("lijia_ProjectionMatrix", tm);
            Shader.SetGlobalTexture("lijia_DepthTexture", _rt);
        }


    }
