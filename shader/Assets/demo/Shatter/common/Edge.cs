using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Roma
{
    public class Edge 
    {
        public int index;
        public Point point0, point1;
        public Vector3 line;

        public Edge(Point point0, Point point1)
        {
            this.point0 = point0;
            this.point1 = point1;
            this.line = point1.position - point0.position;
        }
    }

    public class Point
    {
        public int index;
        public Vector3 position;

        public Point(Vector3 position)
        {
            this.position = position;
        }
    }

    public class Triangle
    {
        public int v0, v1, v2;
        public Point p0, p1, p2;
        public Edge e0, e1, e2;

        public Triangle(int v0, int v1, int v2, 
                        Point p0, Point p1, Point p2,
                        Edge e0, Edge e1, Edge e2)
        {
            this.v0 = v0;
            this.v1 = v1;
            this.v2 = v2;

            this.p0 = p0;
            this.p1 = p1;
            this.p2 = p2;

            this.e0 = e0;
            this.e1 = e1;
            this.e2 = e2;
        }
    }

    public struct EdgeHit
    {
        public float scalar;
        public Edge splitA, splitB;
    }

    public class Hull
    {
        private static float smallestValidLength = 0.01f;   //最小长度
        private static float smallestValidRatio = 0.05f;    // 最小比例

        private Object m_Key = new Object();

        private List<Vector3> m_Vertices;              
        private List<Vector3> m_Normals;
        private List<Vector4> m_Tangents;
        private List<Vector2> m_Uvs;

        private List<Point> m_VertexToPointMap; // 当前对象的点索引，顶点通过顶点索引，获取顶点类，有重复

        private List<Point> m_Points; // 点列表,无重复
        private List<Edge> m_Edges;   // 边列表
        private List<Triangle> m_Triangles; // 面列表

        public Hull(Hull reference)
        {
            int vCount = reference.m_Vertices.Count * 2;
            m_Vertices = new List<Vector3>(vCount);
            m_Normals = new List<Vector3>(vCount);
            m_Tangents = new List<Vector4>(vCount);
            m_Uvs = new List<Vector2>(vCount);

            m_VertexToPointMap = new List<Point>(vCount);


            m_Points = new List<Point>(reference.m_Points.Count * 2);
            m_Edges = new List<Edge>(reference.m_Edges.Count * 2);
            m_Triangles = new List<Triangle>(reference.m_Triangles.Count * 2);
        }

        public Hull(Mesh mesh)
        {
            m_Vertices = new List<Vector3>(mesh.vertices);
            m_Normals = new List<Vector3>(mesh.normals);
            m_Tangents = new List<Vector4>(mesh.tangents);
            m_Uvs = new List<Vector2>(mesh.uv);

            m_VertexToPointMap = new List<Point>(m_Vertices.Count);

            m_Points = new List<Point>();
            m_Edges = new List<Edge>();
            m_Triangles = new List<Triangle>();

            // 添加点列表
            for(int i = 0; i < m_Vertices.Count; i ++)
            {
                Point p;
                AddPoint(m_Vertices[i], out p);
                m_VertexToPointMap.Add(p);
            }

            // 添加边和面
            int[] triList = mesh.triangles;  // 自带三角面的点索引
            for(int i = 0; i < triList.Length / 3; i ++)
            {
                int index = i * 3;
                AddTriangle(triList[index + 0], triList[index + 1], triList[index + 2]);
            }
        }

        private void AddPoint(Vector3 pos, out Point outP)
        {
            foreach(Point item in m_Points)
            {
                if(item.position == pos)
                {
                    outP = item;
                    return;
                }
            }
            outP = new Point(pos);
            m_Points.Add(outP);
        }

        private void AddTriangle(int v0, int v1, int v2)
        {
            Point p0 = m_VertexToPointMap[v0];
            Point p1 = m_VertexToPointMap[v1];
            Point p2 = m_VertexToPointMap[v2];

            Edge e0, e1, e2;
            AddEdge(p0, p1, out e0);
            AddEdge(p1, p2, out e1);
            AddEdge(p2, p0, out e2);

            Triangle tri = new Triangle(v0, v1, v2, p0, p1, p2, e0, e1, e2);
            m_Triangles.Add(tri);
        }

        private void AddEdge(Point p0, Point p1, out Edge outEdge)
        {
            foreach(Edge edge in m_Edges)
            {
                if((edge.point0 == p0 && edge.point1 == p1) ||
                   (edge.point0 == p1 && edge.point1 == p0))
                {
                    outEdge = edge;
                    return;
                }
            }

            outEdge = new Edge(p0, p1);
            m_Edges.Add(outEdge);
        }

        private void AddVertex(Vector3 vertex, Vector3 normal, Vector4 tangent, Vector2 uv, Point point, out int index)
        {
            index = m_Vertices.Count;
            m_Vertices.Add(vertex);
            m_Normals.Add(normal);
            m_Tangents.Add(tangent);
            m_Uvs.Add(uv);

            m_VertexToPointMap.Add(point);
        }

        public bool IsEmpty
        {
            get
            {
                lock (m_Key)
                {
                    return m_Points.Count < 4 || m_Edges.Count < 6 || m_Triangles.Count < 4;
                }
            }
        }

        public void Clear()
        {
            lock (m_Key)
            {
                m_Vertices.Clear();
                m_Normals.Clear();
                m_Tangents.Clear();
                m_Uvs.Clear();

                m_VertexToPointMap.Clear();

                m_Points.Clear();
                m_Edges.Clear();
                m_Triangles.Clear();
            }
        }

        public Mesh GetMesh()
        {
            lock(m_Key)
            {
                if(!IsEmpty)
                {
                    Vector3[] ver = new Vector3[m_Vertices.Count];
                    Vector3[] nor = new Vector3[m_Normals.Count];
                    Vector4[] tan = new Vector4[m_Tangents.Count];
                    Vector2[] uv = new Vector2[m_Uvs.Count];

                    m_Vertices.CopyTo(ver, 0);
                    m_Normals.CopyTo(nor, 0);
                    m_Tangents.CopyTo(tan, 0);
                    m_Uvs.CopyTo(uv, 0);

                    // 获取三角面的顶点信息，每一个3个顶点
                    int[] triList = new int[m_Triangles.Count * 3];
                    int count = 0;
                    foreach(Triangle triangle in m_Triangles)
                    {
                        triList[count++] = triangle.v0;
                        triList[count++] = triangle.v1;
                        triList[count++] = triangle.v2;
                    }

                    Mesh mesh = new Mesh();
                    mesh.vertices = ver;
                    mesh.normals = nor;
                    mesh.tangents = tan;
                    mesh.uv = uv;
                    mesh.triangles = triList;

                    return mesh;
                }
                return null;
            }
        }

        //public void Split(Vector3 localPointOnPlane, Vector3 localPlaneNormal,
        //            bool fillCut, UvMapper uvMapper,
        //            out Hull a, out Hull b)
        //{
        //    lock (m_Key)
        //    {
        //        if(localPlaneNormal == Vector3.zero)
        //        {
        //            localPlaneNormal = Vector3.up;
        //        }

        //        a = new Hull(this);
        //        b = new Hull(this);

        //        SetIndex();

        //        // 存储当前点列表中，在a或在b
        //        bool[] pointAbovePlane;
        //        AssignPoints(a, b, localPointOnPlane, localPlaneNormal, out pointAbovePlane);

        //        // 存储当前顶点列表中，在a或在b的顶点索引
        //        int[] oldToNewVertex;
        //        AssignVertices(a, b, pointAbovePlane, out oldToNewVertex);

        //        // 当前线，是否和分割面相交
        //        bool[] edgeIntersectsPlane;   // 记录与分割面相交的线段索引
        //        EdgeHit[] edgeHits;           // 记录与分割面相交的线段相交信息
        //        AssignEdges(a, b, pointAbovePlane, localPointOnPlane, localPlaneNormal, out edgeIntersectsPlane, out edgeHits);

        //        List<Edge> cutEdgesA, cutEdgesB;

        //        AssignTriangles(a, b, pointAbovePlane, edgeIntersectsPlane, edgeHits, oldToNewVertex, out cutEdgesA, out cutEdgesB);

        //        Clear();
        //    }
        //}

        /// <summary>
        /// 设置点，线的索引
        /// </summary>
        private void SetIndex()
        {
            int pCount = 0;
            foreach(Point point in m_Points)
            {
                point.index = pCount++;
            }
            int eCount = 0;
            foreach(Edge edge in m_Edges)
            {
                edge.index = eCount++;
            }
        }

        private void AssignPoints(Hull a, Hull b, 
            Vector3 pointOnPlane, Vector3 planeNormal, 
            out bool[] pointAbovePlane)
        {
            // 返回点在上下的信息
            pointAbovePlane = new bool[m_Points.Count];
            foreach(Point point in m_Points)
            {
                bool bAbove = Vector3.Dot(point.position - pointOnPlane, planeNormal) > 0.0f;
                pointAbovePlane[point.index] = bAbove;
                if(bAbove)
                {
                    a.m_Points.Add(point);
                }
                else
                {
                    a.m_Points.Add(point);
                }
            }
        }

        private void AssignVertices(Hull a, Hull b, bool[] pointAbovePlane, out int[] oldToNewVertex)
        {
            oldToNewVertex = new int[m_Vertices.Count];
            // 遍历所有顶点，获取点信息，判断是否在切割面的上下，进行添加到不同对象的处理
            for(int i = 0; i < m_Vertices.Count; i ++)
            {
                Point curPont = m_VertexToPointMap[i];
                if(pointAbovePlane[curPont.index])
                {
                    a.AddVertex(m_Vertices[i], m_Normals[i], Vector4.zero, m_Uvs[i].normalized, curPont, out oldToNewVertex[i]);
                }
                else
                {
                    b.AddVertex(m_Vertices[i], m_Normals[i], Vector4.zero, m_Uvs[i].normalized, curPont, out oldToNewVertex[i]);
                }
            }
        }

        private void AssignEdges(Hull a, Hull b, 
            bool[] pointAbovePlane, Vector3 pointOnPlane, Vector3 planeNormal, 
            out bool[] edgeIntersectsPlane, out EdgeHit[] edgeHits)
        {
            edgeIntersectsPlane = new bool[m_Edges.Count];
            edgeHits = new EdgeHit[m_Edges.Count];

            foreach (Edge edge in m_Edges)
            {
                bool abovePlane0 = pointAbovePlane[edge.point0.index];
                bool abovePlane1 = pointAbovePlane[edge.point1.index];
                if(abovePlane0 && abovePlane1)
                {
                    a.m_Edges.Add(edge);
                }
                else if(!abovePlane0 && !abovePlane1)
                {
                    b.m_Edges.Add(edge);
                }
                else
                {
                    // 几何意义，任何两个向量的点积a·b，等同于b在a方向上的投影值，再乘以a的长度
                    float denominator = Vector3.Dot(edge.line, planeNormal);
                    // 起点到切割点的比例
                    float scalar = Mathf.Clamp01(Vector3.Dot(pointOnPlane - edge.point0.position, planeNormal) / denominator);
                    // 交点
                    Vector3 intersection = edge.point0.position + edge.line * scalar;

                    // 创建新的点
                    Point pA = new Point(intersection);
                    Point pB = new Point(intersection);

                    a.m_Points.Add(pA);
                    b.m_Points.Add(pB);

                    // 创建新的线
                    Edge splitA, splitB;
                    if(pointAbovePlane[edge.point0.index])
                    {
                        splitA = new Edge(pA, edge.point0);
                        splitB = new Edge(pB, edge.point1);
                    }
                    else
                    {
                        splitA = new Edge(pA, edge.point1);
                        splitB = new Edge(pB, edge.point0);
                    }

                    a.m_Edges.Add(splitA);
                    b.m_Edges.Add(splitB);
                    // 记录与分割面相交的线段索引
                    edgeIntersectsPlane[edge.index] = true;

                    edgeHits[edge.index] = new EdgeHit();
                    edgeHits[edge.index].scalar = scalar;
                    edgeHits[edge.index].splitA = splitA;
                    edgeHits[edge.index].splitB = splitB;
                }
            }
        }

        private void AssignTriangles(Hull a, Hull b, 
            bool[] pointAbovePlane, bool[] edgeIntersectsPlane, EdgeHit[] edgeHits, int[] oldToNewVertex, 
            out List<Edge> cutEdgesA, out List<Edge> cutEdgesB)
        {
            cutEdgesA = new List<Edge>();
            cutEdgesB = new List<Edge>();

            foreach(Triangle item in m_Triangles)
            {
                bool abovePlane0 = pointAbovePlane[item.p0.index];
                bool abovePlane1 = pointAbovePlane[item.p1.index];
                bool abovePlane2 = pointAbovePlane[item.p2.index];

                if(abovePlane0 && abovePlane1 && abovePlane2)
                {
                    item.v0 = oldToNewVertex[item.v0];
                    item.v1 = oldToNewVertex[item.v1];
                    item.v2 = oldToNewVertex[item.v2];

                    a.m_Triangles.Add(item);
                }
                else if(!abovePlane0 && !abovePlane1 && !abovePlane2)
                {
                    item.v0 = oldToNewVertex[item.v0];
                    item.v1 = oldToNewVertex[item.v1];
                    item.v2 = oldToNewVertex[item.v2];

                    b.m_Triangles.Add(item);
                }
                else
                {
                    // 分割三角面
                    Point topPoint;
                    Edge e0, e1, e2;
                    int v0, v1, v2;
                    // 当前三角面的边0，边1与分割面相交
                    if(edgeIntersectsPlane[item.e0.index] && edgeIntersectsPlane[item.e1.index])
                    {
                        topPoint = item.p1;
                        e0 = item.e0;
                        e1 = item.e1;
                        e2 = item.e2;
                        v0 = item.v0;
                        v1 = item.v1;
                        v2 = item.v2;
                    }
                    else if (edgeIntersectsPlane[item.e1.index] && edgeIntersectsPlane[item.e2.index])
                    {
                        topPoint = item.p2;
                        e0 = item.e1;
                        e1 = item.e2;
                        e2 = item.e0;
                        v0 = item.v1;
                        v1 = item.v2;
                        v2 = item.v0;
                    }
                    else
                    {
                        topPoint = item.p0;
                        e0 = item.e2;
                        e1 = item.e0;
                        e2 = item.e1;
                        v0 = item.v2;
                        v1 = item.v0;
                        v2 = item.v1;
                    }
                    // 此时分割出来的小三角形中，e0,e1都是被分割的边，拿到他们的边分割信息
                    EdgeHit edgeHit0 = edgeHits[e0.index];
                    EdgeHit edgeHit1 = edgeHits[e1.index];
                    // 按照新三角形的顺序，获取被分割边e0,e1的分割比例
                    float scalar0;
                    if(topPoint == e0.point1)    
                    {
                        scalar0 = edgeHit0.scalar;
                    }
                    else
                    {
                        scalar0 = 1.0f - edgeHit0.scalar;
                    }

                    float scalar1;
                    if(topPoint == e1.point0)
                    {
                        scalar1 = edgeHit1.scalar;
                    }
                    else
                    {
                        scalar1 = 1.0f - edgeHit1.scalar;
                    }

                    Edge cutEdgeA, cutEdgeB;
                    if(pointAbovePlane[topPoint.index])
                    {
                        // splitA是上面，那么cutEdgeA就是分割出来的小三角形的底边，在线画图工具中有记录
                        cutEdgeA = new Edge(edgeHit1.splitA.point0, edgeHit0.splitA.point0);
                        // cutEdgeB给分配到底部图形上，当然他是四边形，还需处理，注：此时方向应该和上面相反
                        cutEdgeB = new Edge(edgeHit1.splitB.point0, edgeHit0.splitB.point0);

                        a.m_Edges.Add(cutEdgeA);
                        b.m_Edges.Add(cutEdgeB);

                        SplitTriangle(a, b, 
                                        edgeHit0.splitA, edgeHit1.splitA, cutEdgeA,       // 分割出来的三角形
                                        edgeHit0.splitB, edgeHit1.splitB, cutEdgeB, e2,   // 分割出来的四边形
                                        v0, v1, v2, scalar0, scalar1, oldToNewVertex);
                    }
                    else
                    {
                        cutEdgeA = new Edge(edgeHit0.splitA.point0, edgeHit1.splitA.point0);
                        cutEdgeB = new Edge(edgeHit0.splitB.point0, edgeHit1.splitB.point0);

                        a.m_Edges.Add(cutEdgeA);
                        b.m_Edges.Add(cutEdgeB);

                        SplitTriangle(b, a, edgeHit0.splitB, edgeHit1.splitB, cutEdgeB, edgeHit0.splitA, edgeHit1.splitA, cutEdgeA, e2, v0, v1, v2, scalar0, scalar1, oldToNewVertex);
                    }

                    cutEdgesA.Add(cutEdgeA);
                    cutEdgesB.Add(cutEdgeB);
                }
            }
        }

        /// <summary>
        /// 分割三角形
        /// </summary>
        /// <param name="topHull">a部分</param>
        /// <param name="bottomHull">b部分</param>
        /// <param name="topEdge0">a部分边0</param>
        /// <param name="topEdge1">a部分边1</param>
        /// <param name="topCutEdge">a部分边2-新边</param>
        /// <param name="bottomEdge0">b部分边0</param>
        /// <param name="bottomEdge1">b部分边1</param>
        /// <param name="bottomCutEdge">b部分-新边</param>
        /// <param name="bottomEdge2">b部分边2</param>
        /// <param name="v0">当前三角面的顶点0</param>
        /// <param name="v1">当前三角面的顶点1</param>
        /// <param name="v2">当前三角面的顶点2</param>
        /// <param name="scalar0">分割线0的比例</param>
        /// <param name="scalar1">分割线1的比例</param>
        /// <param name="oldToNewVertex">在a部分或者在b部分的顶点索引</param>
        private void SplitTriangle(Hull topHull, Hull bottomHull, 
                                    Edge topEdge0, Edge topEdge1, Edge topCutEdge, 
                                    Edge bottomEdge0, Edge bottomEdge1, Edge bottomCutEdge, Edge bottomEdge2,
                                    int v0, int v1, int v2, float scalar0, float scalar1, int[] oldToNewVertex)
        {
            Vector3 n0 = m_Normals[v0];
            Vector3 n1 = m_Normals[v1];
            Vector3 n2 = m_Normals[v2];

            Vector4 t0 = m_Tangents[v0];
            Vector4 t1 = m_Tangents[v1];
            Vector4 t2 = m_Tangents[v2];

            Vector2 uv0 = m_Uvs[v0];
            Vector2 uv1 = m_Uvs[v1];
            Vector2 uv2 = m_Uvs[v2];

            // 根据两个顶点的法线和分割比例做插值，得到分割点处顶点的法线
            Vector3 cutNormal0 = new Vector3();
            cutNormal0.x = n0.x + (n1.x - n0.x) * scalar0;
            cutNormal0.y = n0.y + (n1.y - n0.y) * scalar0;
            cutNormal0.z = n0.z + (n1.z - n0.z) * scalar0;
            cutNormal0.Normalize();

            Vector3 cutNormal1 = new Vector3();
            cutNormal1.x = n1.x + (n2.x - n1.x) * scalar1;
            cutNormal1.y = n1.y + (n2.y - n1.y) * scalar1;
            cutNormal1.z = n1.z + (n2.z - n1.z) * scalar1;
            cutNormal1.Normalize();

            // 根据两个顶点的切线和分割比例做插值，得到分割点处顶点的切线
            Vector4 cutTangent0 = new Vector4();
            cutTangent0.x = t0.x + (t1.x - t0.x) * scalar0;
            cutTangent0.y = t0.y + (t1.y - t0.y) * scalar0;
            cutTangent0.z = t0.z + (t1.z - t0.z) * scalar0;
            cutTangent0.Normalize();
            cutTangent0.w = t0.w;

            Vector4 cutTangent1 = new Vector4();
            cutTangent1.x = t1.x + (t2.x - t1.x) * scalar1;
            cutTangent1.y = t1.y + (t2.y - t1.y) * scalar1;
            cutTangent1.z = t1.z + (t2.z - t1.z) * scalar1;
            cutTangent1.Normalize();
            cutTangent1.w = t1.w;

            // 根据两个顶点的uv和分割比例做插值，得到分割点处顶点的uv信息
            Vector2 cutUv0 = new Vector2();
            cutUv0.x = uv0.x + (uv1.x - uv0.x) * scalar0;
            cutUv0.y = uv0.y + (uv1.y - uv0.y) * scalar0;

            Vector2 cutUv1 = new Vector2();
            cutUv1.x = uv1.x + (uv2.x - uv1.x) * scalar1;
            cutUv1.y = uv1.y + (uv2.y - uv1.y) * scalar1;

            // 给上部分三角形，添加分割的两个点，返回顶点索引,用于构建三角形
            int topCutVertex0, topCutVertex1;
            topHull.AddVertex(topEdge0.point0.position, cutNormal0, cutTangent0, cutUv0, topEdge0.point0, out topCutVertex0);
            topHull.AddVertex(topEdge1.point0.position, cutNormal1, cutTangent1, cutUv1, topEdge1.point0, out topCutVertex1);

            // 构建上部分三角形
            Triangle topTri = new Triangle(topCutVertex0, oldToNewVertex[v1], topCutVertex1,
                                            topEdge0.point0, topEdge0.point1, topEdge1.point0, topEdge0, topEdge1, topCutEdge);

            topHull.m_Triangles.Add(topTri);

            // 给下部分四边形，添加分割的两个点，返回顶点索引
            int bottomCutVertex0, bottomCutVertex1;
            bottomHull.AddVertex(bottomEdge0.point0.position, cutNormal0, cutTangent0, cutUv0, bottomEdge0.point0, out bottomCutVertex0);
            bottomHull.AddVertex(bottomEdge1.point0.position, cutNormal1, cutTangent1, cutUv1, bottomEdge1.point0, out bottomCutVertex1);

            // 下部分四边形中，构建的交叉线，分配为2个三角形
            Edge bottomCrossEdge = new Edge(bottomEdge0.point1, bottomEdge1.point0);
            Triangle bottomTri0 = new Triangle(oldToNewVertex[v0], bottomCutVertex0, bottomCutVertex1,
                                                bottomEdge0.point1, bottomEdge0.point0, bottomEdge1.point0,
                                                bottomEdge0, bottomCutEdge, bottomCrossEdge);

            Triangle bottomTri1 = new Triangle(oldToNewVertex[v0], bottomCutVertex1, oldToNewVertex[v2],
                                                bottomEdge0.point1, bottomEdge1.point0, bottomEdge1.point1,
                                                bottomCrossEdge, bottomEdge1, bottomEdge2);

            bottomHull.m_Edges.Add(bottomCrossEdge);
            bottomHull.m_Triangles.Add(bottomTri0);
            bottomHull.m_Triangles.Add(bottomTri1);


        }
    }

 



}



