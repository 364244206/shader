using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class FootPrintManager : MonoBehaviour
{
    public int m_TexSize = 256;
    public int m_WorldSize = 256;
    public int m_FootPrintRadius = 1;

    public Transform m_Player;
    public Transform[] m_FootPrintList;


    public Texture2D m_Texture;
    private Color[] m_ColorBuffer;

    public RawImage m_image;


    void Start()
    {
        m_Texture = new Texture2D(m_TexSize, m_TexSize, TextureFormat.RGBAHalf, false);
        m_Texture.wrapMode = TextureWrapMode.Clamp;
        m_Texture.filterMode = FilterMode.Point;
        m_ColorBuffer = new Color[m_TexSize * m_TexSize];

        m_image.texture = m_Texture;
    }

    private void ClearBuff()
    {
        for (int i = 0, imax = m_ColorBuffer.Length; i < imax; ++i)
        {
            m_ColorBuffer[i].r = 0;
            m_ColorBuffer[i].g = 0;
            m_ColorBuffer[i].b = 0;
            m_ColorBuffer[i].a = 0;
        }
    }

    private void UpdateBuff()
    {
        list.Clear();
        for (int i = 0; i < m_FootPrintList.Length; i++)
        {
            Transform tran = m_FootPrintList[i];
            SetFootPrint(i, tran.position, tran.localEulerAngles);
            Vector4 v = tran.position;
            list.Add(v);
        }
        m_Texture.SetPixels(m_ColorBuffer);
        m_Texture.Apply();
    }

    public Vector3 GetCenterPos()
    {
        return m_Player.position - Vector3.one * m_WorldSize * 0.5f;
    }

    public Vector3 WorldToUv(Vector3 pos, float maxRange)
    {
        return (pos / maxRange) + new Vector3(0.5f, 0.5f, 0.5f);
    }

    public float WorldToUv(float dis, float maxRange)
    {
        return (dis / maxRange);
    }

    public float UvToWorld(float dis, float maxRange)
    {
        return dis *  maxRange;
    }

    public void SetFootPrint(int index, Vector3 worldPos, Vector3 wDir)
    {
        Vector3 wPos = worldPos - GetCenterPos();
        float worldToTex = (float)m_TexSize / m_WorldSize;
       
        // 计算当前探测器边框的4个坐标点，转到材质坐标系
        int xMin = Mathf.RoundToInt((wPos.x - m_FootPrintRadius) * worldToTex);
        int yMin = Mathf.RoundToInt((wPos.z - m_FootPrintRadius) * worldToTex);
        int xMax = Mathf.RoundToInt((wPos.x + m_FootPrintRadius) * worldToTex);
        int yMax = Mathf.RoundToInt((wPos.z + m_FootPrintRadius) * worldToTex);
        // 当前探测器的位置
        int texPosX = Mathf.RoundToInt(wPos.x * worldToTex);
        int texPosY = Mathf.RoundToInt(wPos.z * worldToTex);
        // 防止越界
        texPosX = Mathf.Clamp(texPosX, 0, m_TexSize - 1);
        texPosY = Mathf.Clamp(texPosY, 0, m_TexSize - 1);
        // 探测半径
        int radius = Mathf.RoundToInt((m_FootPrintRadius) * (m_FootPrintRadius) * worldToTex * worldToTex);

        for (int y = yMin; y < yMax; y++)
        {
            if (y >= 0 && y < m_TexSize)
            {
                for (int x = xMin; x < xMax; x++)
                {
                    if (x >= 0 && x < m_TexSize)
                    {
                        int xd = x - texPosX;
                        int yd = y - texPosY;
                        int dist = xd * xd + yd * yd;

                        float a = m_ColorBuffer[x + y * m_TexSize].a;
                        float preDis = UvToWorld(a, 128);
                        if (a == 0 /*|| preDis > dist*/)
                        {
                            Vector3 uvPos = WorldToUv(worldPos, 1024);
                            float angel = wDir.y / 360;
                            float dis = WorldToUv(dist, 128);
                            if(dis == 0)
                            {
                                dis = 0.01f;
                            }
                            Color col = new Color(index, angel, uvPos.z, dis);
                            
                            m_ColorBuffer[x + y * m_TexSize] = col;
                            //m_ColorBuffer[x + y * m_TexSize].a = (byte)Mathf.Sqrt(dist);
                        }
                    }
                }
            }
        }
    }

    void Update()
    {
        ClearBuff();
        UpdateBuff();
        UpdateShader();
    }
    List<Vector4> list = new List<Vector4>(); 
    private void UpdateShader()
    {
        float w2u = 1f / m_WorldSize;
        Vector3 worldToUv = Vector3.one * w2u;

        Shader.SetGlobalTexture("_FootPrintsTex", m_Texture);
        Shader.SetGlobalVector("_FootPrintTexCenter", GetCenterPos());
        Shader.SetGlobalVector("_FootPrintTexWorldToUv", worldToUv);
        Shader.SetGlobalFloat("_FootPrintRadius", m_FootPrintRadius);
        Shader.SetGlobalVectorArray("_FootPrintCenterPos", list);
        //Shader.SetGlobalVector("_testCenterPos", m_FootPrintList[2].position);
    }
}
