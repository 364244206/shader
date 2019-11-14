using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class UIGlow : BaseMeshEffect
{
    public Color m_GlowColor = new Color(0, 1, 0, 0.4f);
    public Vector2 m_GlowDistance = new Vector2(20.0f, 10.0f);
    [Range(0.1f, 1.0f)]
    public float m_GlowFactor = 0.5f;

    private List<UIVertex> m_VetexList = new List<UIVertex>();

    protected override void Awake()
    {
        base.Awake();

        Shader shader = Shader.Find("UI/UIGlow");
        graphic.material = new Material(shader);

        graphic.canvas.additionalShaderChannels |= AdditionalCanvasShaderChannels.TexCoord1;
        _Refresh();
    }

#if UNITY_EDITOR
    protected override void OnValidate()
    {
        base.OnValidate();
        _Refresh();
    }
#endif

    private void _Refresh()
    {
        if (graphic.material != null)
        {
            graphic.material.SetColor("_OuterGlowColor", this.m_GlowColor);
            graphic.material.SetFloat("_GlowFactor", this.m_GlowFactor);
            // 刷新信息
            graphic.SetVerticesDirty();
        }
    }

    public override void ModifyMesh(VertexHelper vh)
    {
        // 通过原生接口，获取顶点信息
        vh.GetUIVertexStream(m_VetexList);
        // 拷贝一组新的顶点
        CopyVertices();
        // 扩大顶点
        _ProcessVertices();
        // 更新列表顶点信息
        vh.Clear();
        vh.AddUIVertexTriangleStream(m_VetexList);
    }

    public void CopyVertices()
    {
        int start = 0;
        int end = m_VetexList.Count;

        int count = end - start;
        int neededCapacity = m_VetexList.Count + count;
        if (m_VetexList.Capacity < neededCapacity)
            m_VetexList.Capacity *= 2;

        // Add 
        UIVertex vt = default(UIVertex);
        for (int i = 0; i < count; i++)
        {
            m_VetexList.Add(vt);
        }

        // Move
        for (int i = m_VetexList.Count - 1; count <= i; i--)
        {
            m_VetexList[i] = m_VetexList[i - count];
        }

        // 将阴影的顶点放到前面，并设置顶点色
        for (int i = 0; i < count; ++i)
        {
            vt = m_VetexList[i + start + count];
            Vector3 v = vt.position;
            vt.position.Set(v.x, v.y , v.z);

            vt.color = m_GlowColor;
            vt.uv1 = Vector2.one;
            m_VetexList[i] = vt;
        }
    }

    private void _ProcessVertices()
    {
        // 遍历三角面
        for (int i = 0, count = m_VetexList.Count - 3; i <= count; i += 3)
        {
            if(m_VetexList[i].uv1 == Vector2.zero)
            {
                continue;
            }
            // 当前三角面的三个顶点
            var v1 = m_VetexList[i];
            var v2 = m_VetexList[i + 1];
            var v3 = m_VetexList[i + 2];

            // 计算三角面中心点
            float minX = _Min(v1.position.x, v2.position.x, v3.position.x);
            float minY = _Min(v1.position.y, v2.position.y, v3.position.y);
            float maxX = _Max(v1.position.x, v2.position.x, v3.position.x);
            float maxY = _Max(v1.position.y, v2.position.y, v3.position.y);
            var posCenter = new Vector2(minX + maxX, minY + maxY) * 0.5f;

            // 计算原始顶点坐标和UV的方向，此代码只是注释，其作用是扩大顶点时，让UV缩小，保持采样图像的结果不扩大
            //Vector2 triX, triY, uvX, uvY;
            //Vector2 pos1 = v1.position;
            //Vector2 pos2 = v2.position;
            //Vector2 pos3 = v3.position;
            //if (Mathf.Abs(Vector2.Dot((pos2 - pos1).normalized, Vector2.right))
            //    > Mathf.Abs(Vector2.Dot((pos3 - pos2).normalized, Vector2.right)))
            //{
            //    triX = pos2 - pos1;
            //    triY = pos3 - pos2;
            //    uvX = v2.uv0 - v1.uv0;
            //    uvY = v3.uv0 - v2.uv0;
            //}
            //else
            //{
            //    triX = pos3 - pos2;
            //    triY = pos2 - pos1;
            //    uvX = v3.uv0 - v2.uv0;
            //    uvY = v2.uv0 - v1.uv0;
            //}

            // 计算原始UV框,废除
            //var uvMin = _Min(v1.uv0, v2.uv0, v3.uv0);
            //var uvMax = _Max(v1.uv0, v2.uv0, v3.uv0);
            //var uvOrigin = new Vector4(uvMin.x, uvMin.y, uvMax.x, uvMax.y);

            // 设置新的Position和UV
            v1 = _SetNewPosAndUV(v1, this.m_GlowDistance, posCenter/*, triX, triY, uvX, uvY, uvOrigin*/);
            v2 = _SetNewPosAndUV(v2, this.m_GlowDistance, posCenter/*, triX, triY, uvX, uvY, uvOrigin*/);
            v3 = _SetNewPosAndUV(v3, this.m_GlowDistance, posCenter/*, triX, triY, uvX, uvY, uvOrigin*/);

            m_VetexList[i] = v1;
            m_VetexList[i + 1] = v2;
            m_VetexList[i + 2] = v3;
        }
    }

    private static UIVertex _SetNewPosAndUV(UIVertex pVertex, Vector2 pOutLineWidth,
        Vector2 pPosCenter /*,
        Vector2 pTriangleX, Vector2 pTriangleY,
        Vector2 pUVX, Vector2 pUVY,
        Vector4 pUVOrigin*/)
    {
        // Position
        var pos = pVertex.position;
        // 当前顶点X大于中心点，则需要+扩大的宽度，否则-扩大的宽度
        var posXOffset = pos.x > pPosCenter.x ? pOutLineWidth.x : -pOutLineWidth.x;
        var posYOffset = pos.y > pPosCenter.y ? pOutLineWidth.y : -pOutLineWidth.y;
        // 对当前顶点位置做偏移
        pos.x += posXOffset;
        pos.y += posYOffset;
        pVertex.position = pos;

        // 缩小原始UV0
        //var uv = pVertex.uv0;
        //// 判断边向量2-3与Vector2.right的方向，如果小于90度，则方向相同
        //// 然后通过 uv差值/边长度 = (偏移的)ui差值/(偏移的)边长度，求出uv的X分量的偏移量
        //uv += pUVX / pTriangleX.magnitude * posXOffset * (Vector2.Dot(pTriangleX, Vector2.right) > 0 ? 1 : -1);
        //// 再用同样的方式求当前顶点的Y的分量
        //uv += pUVY / pTriangleY.magnitude * posYOffset * (Vector2.Dot(pTriangleY, Vector2.up) > 0 ? 1 : -1);
        //pVertex.uv0 = uv;

        // 重新更改UV信息，本身是【0-1】，现在改成【-1，1】，0在中间，便于shader中计算透明度
        Vector2 newUv = Vector2.zero;
        float uvXOffset = pos.x > pPosCenter.x ? 1 : -1;
        float uvYOffset = pos.y > pPosCenter.y ? 1 : -1;
        newUv.x += uvXOffset;
        newUv.y += uvYOffset;
        pVertex.uv0 = newUv;
        return pVertex;
    }


    private static float _Min(float pA, float pB, float pC)
    {
        return Mathf.Min(Mathf.Min(pA, pB), pC);
    }


    private static float _Max(float pA, float pB, float pC)
    {
        return Mathf.Max(Mathf.Max(pA, pB), pC);
    }


    private static Vector2 _Min(Vector2 pA, Vector2 pB, Vector2 pC)
    {
        return new Vector2(_Min(pA.x, pB.x, pC.x), _Min(pA.y, pB.y, pC.y));
    }


    private static Vector2 _Max(Vector2 pA, Vector2 pB, Vector2 pC)
    {
        return new Vector2(_Max(pA.x, pB.x, pC.x), _Max(pA.y, pB.y, pC.y));
    }

}
