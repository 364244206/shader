using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public class mainText2 : MonoBehaviour {

    public int m_texSize = 128;
    public int m_worldSize = 512;
    public Transform m_player;
    public Transform[] m_listRevealer;
    private int m_range = 10;

    public Texture2D m_texture;
    private Color32[] m_curBuffer;

    void Start ()
    {
        InitBuff();
    }
	
	void Update ()
    {
        ClearBuff();
        UpdateBuff();
    }

    public void InitBuff()
    {
        m_texture = new Texture2D(m_texSize, m_texSize, TextureFormat.RFloat, false);
        m_texture.wrapMode = TextureWrapMode.Clamp;
        m_curBuffer = new Color32[m_texSize * m_texSize];
    }

    private void ClearBuff()
    {
        for (int i = 0, imax = m_curBuffer.Length; i < imax; ++i)
        {
            m_curBuffer[i] = m_curBuffer[i];
            m_curBuffer[i].r = 0;
        }
    }

    private void UpdateBuff()
    {
        for (int i = 0; i < m_listRevealer.Length; i++)
        {
            SetBuff(false, m_listRevealer[i]);
        }
        SetBuff(true, m_player);
        m_texture.SetPixels32(m_curBuffer);
        m_texture.Apply();
    }

    private void SetBuff(bool bPlayer, Transform p)
    {
        Vector3 pos = p.position;

        pos += Vector3.one * m_worldSize * 0.5f;
        pos -= m_player.position;
        float worldToTex = (float)m_texSize / m_worldSize;

        // 计算当前探测器边框的4个坐标点，转到材质坐标系
        int xMin = Mathf.RoundToInt((pos.x - m_range) * worldToTex);
        int yMin = Mathf.RoundToInt((pos.z - m_range) * worldToTex);
        int xMax = Mathf.RoundToInt((pos.x + m_range) * worldToTex);
        int yMax = Mathf.RoundToInt((pos.z + m_range) * worldToTex);
        // 当前探测器的位置
        int texPosX = Mathf.RoundToInt(pos.x * worldToTex);
        int texPosY = Mathf.RoundToInt(pos.z * worldToTex);
        // 防止越界
        texPosX = Mathf.Clamp(texPosX, 0, m_texSize - 1);
        texPosY = Mathf.Clamp(texPosY, 0, m_texSize - 1);
        // 探测半径
        int radius = Mathf.RoundToInt((m_range) * (m_range) * worldToTex * worldToTex);

        for (int y = yMin; y < yMax; y++)
        {
            if (y >= 0 && y < m_texSize)
            {
                for (int x = xMin; x < xMax; x++)
                {
                    if (x >= 0 && x < m_texSize)
                    {
                        // 计算当前探测器的位置和当前遍历点的距离
                        int xd = x - texPosX;
                        int yd = y - texPosY;
                        // 当前坐标和探测器坐标的距离
                        int dist = xd * xd + yd * yd;
                        // 当前坐标距离<探测半径时，该点记录红色
                        if (dist < radius)
                        {
                            m_curBuffer[x + y * m_texSize].r = 255;
                        }
                    }
                }
            }
        }
    }

    private void OnDrawGizmos()
    {
        Vector3 pos = m_player.transform.position;
        float range = m_worldSize * 0.5f;
        Debug.DrawLine(pos + new Vector3(-range, 0, -range), pos + new Vector3(range,0,  -range));
        Debug.DrawLine(pos + new Vector3(-range,0 , -range), pos + new Vector3(-range,0,  range));
        Debug.DrawLine(pos + new Vector3(-range, 0, range), pos + new Vector3(range,0 , range));
        Debug.DrawLine(pos + new Vector3(range, 0,  -range), pos + new Vector3(range, 0, range));
    }
}
