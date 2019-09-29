using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public enum eCheckType
{
    Circle,
    LOS,
}

public class FowSys : MonoBehaviour
{
    public int m_texSize = 128;
    public int m_worldSize = 128;
    public int m_rayHeight = 20;
    public eCheckType m_checkType = eCheckType.Circle;
    public LayerMask m_raycastMask = -1;

    // 更新缓冲区频率
    public float m_updateBufferTime;
    public float m_updateBufferInterval = 0.5f;
    // 融合时间
    public bool m_bBlend = true;
    public float m_blendTime;
    public float m_blendMaxTime = 1;

    private int[,] m_heightInfo;
    private Color32[] m_curBuffer;
    private Color32[] m_newBuffer;
    private Color32[] m_blurTempBuffer;

    // 当前材质信息
    public Texture2D m_curTexture;
    // 最新材质信息
    public Texture2D m_newTexture;

    private List<MyRevealer> m_listRevealer = new List<MyRevealer>();
    static public FowSys instance;

    public void Init()
    {
        instance = this;

        m_heightInfo = new int[m_texSize, m_texSize];

        m_curBuffer = new Color32[m_texSize * m_texSize];
        m_newBuffer = new Color32[m_texSize * m_texSize];
        m_blurTempBuffer = new Color32[m_texSize * m_texSize];

        GetHeightData();
        UpdateBuffer();
    }

    public void AddRev(MyRevealer rev)
    {
        m_listRevealer.Add(rev);
    }

    /// <summary>
    /// demo临时这么写
    /// 整合到项目时高度数据应该在打包场景时获取
    /// </summary>
    private void GetHeightData()
    {
        float texToWorld = (float)m_worldSize / m_texSize;
        Vector3 startPos = Vector3.zero;
        startPos.y = m_rayHeight;
        // 贴图和世界位置都从左下的00开始
        for (int z = 0; z < m_texSize; z++)
        {
            startPos.z = z * texToWorld;
            for (int x = 0; x < m_texSize; x++)
            {
                startPos.x = x * texToWorld;
                RaycastHit hit;
                if (Physics.Raycast(new Ray(startPos, Vector3.down), out hit, m_rayHeight, m_raycastMask))
                {
                    m_heightInfo[x, z] = WorldToTexHeight(m_rayHeight - hit.distance);
                    continue;
                }
                m_heightInfo[x, z] = 0;
            }
        }
    }

    private int WorldToTexHeight(float h)
    {
        int val = Mathf.RoundToInt(h / m_rayHeight * 255);
        return Mathf.Clamp(val, 0, 255);
    }

    private void UpdateBuffer()
    {
        for (int i = 0; i < m_listRevealer.Count; i++)
        {
            if (m_checkType == eCheckType.LOS)
            {
                RevealUsingLOS(m_listRevealer[i]);
            }
            else
            {
                RevealUsingRadius(m_listRevealer[i]);
            }
        }
        // 更新模糊数据
        UpdateBlurData();
    }

    /// <summary>
    /// 获取当前探测器的可见区域
    /// </summary>
    private void RevealUsingRadius(MyRevealer rev)
    {
        Vector3 pos = rev.m_curPos;
        float worldToTex = (float)m_texSize / m_worldSize;
        // 计算当前探测器边框的4个坐标点，转到材质坐标系
        int xMin = Mathf.RoundToInt((pos.x - rev.range) * worldToTex);
        int yMin = Mathf.RoundToInt((pos.z - rev.range) * worldToTex);
        int xMax = Mathf.RoundToInt((pos.x + rev.range) * worldToTex);
        int yMax = Mathf.RoundToInt((pos.z + rev.range) * worldToTex);
        // 当前探测器的位置
        int texPosX = Mathf.RoundToInt(pos.x * worldToTex);
        int texPosY = Mathf.RoundToInt(pos.z * worldToTex);
        // 防止越界
        texPosX = Mathf.Clamp(texPosX, 0, m_texSize - 1);
        texPosY = Mathf.Clamp(texPosY, 0, m_texSize - 1);
        // 探测半径
        int radius = Mathf.RoundToInt(rev.range * rev.range * worldToTex * worldToTex);
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
                            m_newBuffer[x + y * m_texSize].r = 255;
                        }
                    }
                }
            }
        }
    }

    private void RevealUsingLOS(MyRevealer r)
    {
        Vector3 pos = r.m_curPos;
        float worldToTex = (float)m_texSize / m_worldSize;
        // 获取周围的四个点，并转到材质坐标
        int xMin = Mathf.RoundToInt((pos.x - r.range) * worldToTex);
        int yMin = Mathf.RoundToInt((pos.z - r.range) * worldToTex);
        int xMax = Mathf.RoundToInt((pos.x + r.range) * worldToTex);
        int yMax = Mathf.RoundToInt((pos.z + r.range) * worldToTex);
        // 当前探测器在材质的坐标
        int texPosX = Mathf.RoundToInt(pos.x * worldToTex);
        int texPosY = Mathf.RoundToInt(pos.z * worldToTex);
        // 防止越界
        texPosX = Mathf.Clamp(texPosX, 0, m_texSize - 1);
        texPosY = Mathf.Clamp(texPosY, 0, m_texSize - 1);
        // 材质坐标系中探测范围的平方
        int radius = Mathf.RoundToInt(r.range * r.range * worldToTex * worldToTex);
        // 材质坐标系中探测器的高度
        int texHeight = WorldToTexHeight(r.m_sightHeight);
        // 遍历每个点
        for (int y = yMin; y < yMax; y++)
        {
            if (y > -1 && y < m_texSize)            // 在贴图尺寸范围内
            {
                for (int x = xMin; x < xMax; x++)
                {
                    if (x > -1 && x < m_texSize)    // 在贴图尺寸范围内
                    {
                        int xd = x - texPosX;
                        int yd = y - texPosY;
                        int dist = xd * xd + yd * yd;
                        // 当前坐标距离<探测半径时才处理
                        if (dist < radius)
                        {
                            if (IsVisiable(texPosX, texPosY, x, y, texHeight))
                            {
                                m_newBuffer[x + y * m_texSize].r = 255;
                            }
                        }
                    }
                }
            }
        }
    }

    /// <summary>
    /// 通过对比高度检测两点是否可见
    /// 用到Bresenham快速画直线算法
    /// </summary>
    private bool IsVisiable(int x1, int y1, int x2, int y2, int sightHeight)
    {
        // 起点
        int x = x1;
        int y = y1;
        // xy差值
        int dx = x2 - x1;
        int dy = y2 - y1;
        // 单位增量
        int ux = (dx > 0) ? 1 : -1;
        int uy = (dy > 0) ? 1 : -1;
        // 差值取绝对值
        dx = (dx < 0) ? dx * -1 : dx;
        dy = (dy < 0) ? dy * -1 : dy;
        // 遍历到终点过程中的点，以较长的轴向累加
        if (dx > dy)
        {
            // 初始判别式
            int p = 2 * dy - dx;
            for (int i = 0; i <= dx; i++)
            {
                if (sightHeight < m_heightInfo[x, y]) // 如果中途遇比视野高的障碍就中止
                    return false;
                x += ux;
                if (p >= 0)
                {
                    y += uy;
                    p += 2 * (dy - dx);
                }
                else
                {
                    p += 2 * dy;
                }
            }
        }
        else
        {
            int p = 2 * dx - dy;
            for (int i = 0; i <= dy; i++)
            {
                if (sightHeight < m_heightInfo[x, y])
                    return false;
                y += uy;
                if (p >= 0)
                {
                    x += ux;
                    p += 2 * (dx - dy);
                }
                else
                {
                    p += 2 * dx;
                }
            }
        }
        return true;
    }

    /// <summary>
    /// 取每个点周围的8个点累加，取平均值得到模糊数据
    /// </summary>
    private void UpdateBlurData()
    {
        Color32 c;
        for (int y = 0; y < m_texSize; ++y)
        {
            int yw = y * m_texSize;
            int yw0 = (y - 1);
            if (yw0 < 0)
                yw0 = 0;
            int yw1 = (y + 1);
            if (yw1 == m_texSize)
                yw1 = y;

            yw0 *= m_texSize;
            yw1 *= m_texSize;

            for (int x = 0; x < m_texSize; x++)
            {
                int x0 = (x - 1);
                if (x0 < 0)
                    x0 = 0;
                int x1 = (x + 1);
                if (x1 == m_texSize)
                    x1 = x;

                int index = x + yw;
                int val = m_newBuffer[index].r;

                val += m_newBuffer[x0 + yw].r;
                val += m_newBuffer[x1 + yw].r;
                val += m_newBuffer[x + yw0].r;
                val += m_newBuffer[x + yw1].r;

                val += m_newBuffer[x0 + yw0].r;
                val += m_newBuffer[x1 + yw0].r;
                val += m_newBuffer[x0 + yw1].r;
                val += m_newBuffer[x1 + yw1].r;

                c = m_blurTempBuffer[index];
                c.r = (byte)(val / 9);
                m_blurTempBuffer[index] = c;
            }
        }

        // 模糊数据交给m_newBuffer
        Color32[] temp = m_newBuffer;
        m_newBuffer = m_blurTempBuffer;
        m_blurTempBuffer = temp;
    }

    private void UpdateTexture()
    {
        if (m_curTexture == null && m_newTexture == null)
        {
            m_curTexture = new Texture2D(m_texSize, m_texSize, TextureFormat.ARGB32, false);
            m_curTexture.wrapMode = TextureWrapMode.Clamp;
            m_newTexture = new Texture2D(m_texSize, m_texSize, TextureFormat.ARGB32, false);
            m_newTexture.wrapMode = TextureWrapMode.Clamp;
        }
        m_curTexture.SetPixels32(m_curBuffer);
        m_curTexture.Apply();
        m_newTexture.SetPixels32(m_newBuffer);
        m_newTexture.Apply();
    }


    /// <summary>
    /// 可在移动状态时才开启心跳
    /// </summary>
    private void Update()
    {
        if (!m_bBlend)
        {
            m_updateBufferTime += Time.deltaTime;
            if (m_updateBufferTime > m_updateBufferInterval)
            {
                for (int i = 0, imax = m_curBuffer.Length; i < imax; ++i)
                {
                    m_curBuffer[i] = m_newBuffer[i];
                    m_newBuffer[i].r = 0;
                }
                UpdateBuffer();
                m_updateBufferTime = 0;
                // 更新之后开始融合
                m_bBlend = true;
                m_blendTime = 0;
            }
        }
        else
        {
            m_blendTime += Time.deltaTime / m_blendMaxTime;
            if (m_blendTime >= 1)
            {
                m_bBlend = false;
            }
        }
        UpdateTexture();
    }

    /// <summary>
    /// 是否可见
    /// </summary>
    public bool IsVisible(Vector3 pos)
    {
        if (m_curBuffer == null)
            return false;

        float worldToTex = (float)m_texSize / m_worldSize;
        int texX = Mathf.RoundToInt(pos.x * worldToTex);
        int texY = Mathf.RoundToInt(pos.z * worldToTex);

        texX = Mathf.Clamp(texX, 0, m_texSize - 1);
        texY = Mathf.Clamp(texY, 0, m_texSize - 1);
        int index = texX + texY * m_texSize;
        return m_curBuffer[index].r > 0 || m_newBuffer[index].r > 0;
    }
}