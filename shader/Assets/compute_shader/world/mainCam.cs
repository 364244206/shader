using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
public class mainCam : MonoBehaviour {

    public mainText2 m_main;

    public Shader shader;
    public Matrix4x4 inverseMvp;
    private Material mat;
    private Camera cam;

    public RawImage image;
    public bool bCam;
	// Use this for initialization
	void Start () {
        cam = GetComponent<Camera>();
        cam.depthTextureMode = DepthTextureMode.Depth;

        mat = new Material(shader);
        mat.hideFlags = HideFlags.HideAndDontSave;


        image.texture = m_main.m_texture;
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (!bCam)
            return;

        //世界转投影的逆矩阵
        inverseMvp = (cam.projectionMatrix * cam.worldToCameraMatrix).inverse;
        Vector3 worldToUv = new Vector3(1f / m_main.m_worldSize, 1f / m_main.m_worldSize, 1f / m_main.m_worldSize);
        Vector4 camPos = cam.transform.position;

        mat.SetTexture("_tex", m_main.m_texture);
        mat.SetVector("_pos", m_main.m_player.position - Vector3.one * m_main.m_worldSize * 0.5f);
        mat.SetVector("_camPos", camPos);
        mat.SetVector("_worldToUv", worldToUv);
        mat.SetMatrix("_InverseMVP", inverseMvp);     // 屏幕转世界
        Graphics.Blit(source, destination, mat);
    }

    // Update is called once per frame
    void Update () {
        if (bCam)
            return;
        inverseMvp = (cam.projectionMatrix * cam.worldToCameraMatrix).inverse;
        Vector4 camPos = cam.transform.position;
        Vector3 worldToUv = new Vector3(1f / m_main.m_worldSize, 1f / m_main.m_worldSize, 1f / m_main.m_worldSize);

        Shader.SetGlobalTexture("_tex1", m_main.m_texture);
        Shader.SetGlobalVector("_pos1", m_main.m_player.position - Vector3.one * m_main.m_worldSize * 0.5f);
        Shader.SetGlobalVector("_camPos1", camPos);
        Shader.SetGlobalVector("_worldToUv1", worldToUv);
    }
}
