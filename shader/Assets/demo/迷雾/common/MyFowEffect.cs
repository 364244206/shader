using UnityEngine;
using UnityEditor;

public class MyFowEffect : MonoBehaviour
{
    public Shader shader;
    public Color m_maskColor = new Color(0.05f, 0.05f, 0.05f, 1f);
    private Camera m_cam;
    private FowSys m_fog;
    private Matrix4x4 m_inverseMVP;
    private Material m_mat;

    private void Start()
    {
        m_cam = GetComponent<Camera>();
        m_cam.depthTextureMode = DepthTextureMode.Depth;

        if (m_fog == null)
        {
            m_fog = FindObjectOfType(typeof(FowSys)) as FowSys;
        }
        if (m_mat == null)
        {
            m_mat = new Material(shader);
            m_mat.hideFlags = HideFlags.HideAndDontSave;
        }
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        // 投影矩阵 * 世界转摄像机矩阵 = 世界坐标转摄像机投影坐标 的 逆向矩阵
        // 摄像机投影坐标转世界坐标的矩阵
        m_inverseMVP = (m_cam.projectionMatrix * m_cam.worldToCameraMatrix).inverse;
        // 世界坐标系转UV坐标系
        float worldToUv = 1f / m_fog.m_worldSize;
        // 摄像机位置
        Vector4 camPos = m_cam.transform.position;
        Vector2 param = new Vector2(worldToUv, m_fog.m_blendTime);

        m_mat.SetColor("m_maskColor", m_maskColor);       // 无法看到的区域颜色
        m_mat.SetVector("_CamPos", camPos);
        m_mat.SetVector("_Params", param);                // 参数
        m_mat.SetMatrix("_InverseMVP", m_inverseMVP);     // 屏幕转世界
        m_mat.SetTexture("_FogTex0", m_fog.m_curTexture);    // 当前贴图
        m_mat.SetTexture("_FogTex1", m_fog.m_newTexture);    // 新的贴图
        Graphics.Blit(source, destination, m_mat);
    }
}