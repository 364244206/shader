using UnityEngine;
using UnityEditor;

public class MeshUtils
{

   /// <summary>
   /// 
   /// </summary>
   /// <param name="origin"></param>
   /// <param name="right">x方向长度</param>
   /// <param name="forward">z方向长度</param>
   /// <param name="vertNumX">x方向顶点数</param>
   /// <param name="vertNumZ">z方向顶点数</param>
   /// <param name="uvStart">0-1</param>
   /// <param name="uvEnd">0-1</param>
   /// <returns></returns>
    public static Mesh GeneratePlane(Vector3 origin, 
        Vector3 axisX, Vector3 axisZ,
        int vertNumX, int vertNumZ,
        Vector2 uvStart, Vector2 uvEnd)
    {
        int vertNum = vertNumX * vertNumZ;
        Vector3[] vertices = new Vector3[vertNum];
        Vector3[] normals = new Vector3[vertNum];
        Vector2[] uvs = new Vector2[vertNum];
        // 三角面的顶点信息
        int[] triangles = new int[(vertNumX - 1) * (vertNumZ - 1) * 2 * 3];
        Vector3 normal = Vector3.Cross(axisX, axisZ);

        for(int i = 0; i < vertices.Length; i ++)
        {
            int xIndex = i / vertNumX; //x
            int yIndex = i % vertNumX; //y
            float localU = xIndex / (vertNumX - 1f);
            float localV = yIndex / (vertNumZ - 1f);
            // 获取当前顶点的位置
            vertices[i] = origin + localU * axisX + localV * axisZ;
            normals[i] = normal;
            uvs[i].x = Mathf.Lerp(uvStart.x, uvEnd.x, localU);
            uvs[i].y = Mathf.Lerp(uvStart.y, uvEnd.y, localV);
        }

        // ---------------------
        // |      / |       /  |
        // |    /   |     /    |
        // |  /     |   /      |
        // |/       | /        |
        // ---------------------
        // 2 
        // 1
        // 0 1 2
        int vertexIndex = 0;
        for(int iX = 0; iX < vertNumX - 1; iX++)
        {
            for(int iZ = 0; iZ < vertNumZ - 1; iZ ++)
            {
                // 右下三角形
                triangles[vertexIndex++] = (iX + 0) * vertNumX + (iZ + 0);
                triangles[vertexIndex++] = (iX + 1) * vertNumX + (iZ + 1);
                triangles[vertexIndex++] = (iX + 0) * vertNumX + (iZ + 0);
                // 左上三角形
                triangles[vertexIndex++] = (iX + 0) * vertNumX + (iZ + 0);
                triangles[vertexIndex++] = (iX + 0) * vertNumX + (iZ + 1);
                triangles[vertexIndex++] = (iX + 1) * vertNumX + (iZ + 1);
            }
        }

        Mesh mesh = new Mesh();
        mesh.name = vertNumX + "x" + vertNumZ;
        mesh.vertices = vertices;
        mesh.uv = uvs;
        mesh.triangles = triangles;

        mesh.RecalculateBounds();
        return mesh;
    }

}