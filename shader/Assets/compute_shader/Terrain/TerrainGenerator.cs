using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using System;

public class TerrainGenerator : MonoBehaviour
{
    [Serializable]
    public class RenderSettings
    {
        public ShadowCastingMode shadowCastingMode = ShadowCastingMode.On;
        public bool ReceiveShadows = true;
        public bool DynamicOccluded = true;
    }

    [Serializable]
    public class ChunkLODSetting
    {
        [Range(4, 200)]
        public int Size = 200;

        [Range(0, 1)]
        [Tooltip("当前LOD的比例")]
        public float ScreenHeight;

        [Range(0, 1)]
        [Tooltip("交叉淡入淡出的过渡比例")]
        public float FadeTransitionWidth = 0.5f;

        [Tooltip("忽略LOD组的控制")]
        public bool IgnoreLodGroup = false;

        public RenderSettings RenderSettings;
    }

    [Header("Terrain settings")]
    public bool GenerateOnStart;
    public Vector3 Size = new Vector3(256, 10, 256);
    // 分块数量
    public int ChunksX = 16;
    public int ChunksZ = 16;
    // LOD模式
    public ChunkLODSetting[] LODSettings;
    public LODFadeMode LodFadeMode = LODFadeMode.CrossFade;
    public bool AnimateLodCrossFading = true;

    [Header("Materials")]
    public Material[] Materials;
    public bool InstantiateMaterials;


    public MeshCollider m_Ms;
    void Start()
    {
        if (GenerateOnStart)
            Generate();
    }

    [ContextMenu("Generate Terrain")]
    public void Generate()
    {
        // 单元格尺寸
        Vector3 chunkSize = new Vector3(Size.x / ChunksX, Size.y, Size.z / ChunksZ);
        foreach (Transform child in transform)
            Destroy(child);

        // 遍历每一块
        for (int z = 0; z < ChunksZ; z++)
        {
            for (int x = 0; x < ChunksX; x++)
            {
                // 每一块的纹理坐标【0-1】
                Vector2 uvStart = new Vector2((float)x / ChunksX, (float)z / ChunksZ);
                Vector2 uvEnd = new Vector2((float)(x + 1) / ChunksX, (float)(z + 1) / ChunksZ);

                // 创建单元格
                GameObject group = new GameObject(x + "_" + z);
                group.transform.position = new Vector3(x * chunkSize.x, 0, z * chunkSize.z);
                group.transform.SetParent(transform, false);

                LODGroup lodGroup = group.AddComponent<LODGroup>();
                lodGroup.fadeMode = LodFadeMode;
                lodGroup.animateCrossFading = AnimateLodCrossFading;
                List<LOD> lods = new List<LOD>();
                for(int i = 0; i < LODSettings.Length; i ++)
                {
                    ChunkLODSetting setting = LODSettings[i];
                    // 生成单元格内容
                    GameObject chunk = GenerateChunk(chunkSize, uvStart, uvEnd, setting, i);
                    if (chunk == null)
                        continue;
                    chunk.transform.SetParent(group.transform, false);
                    // 记录lod信息
                    if (!setting.IgnoreLodGroup)
                    {
                        Renderer chunkRender = chunk.GetComponent<Renderer>();
                        LOD lod = new LOD();
                        lod.screenRelativeTransitionHeight = setting.ScreenHeight;
                        lod.fadeTransitionWidth = setting.FadeTransitionWidth;
                        lod.renderers = new Renderer[] { chunkRender };
                        lods.Add(lod);
                    }
                }
                lodGroup.SetLODs(lods.ToArray());
                lodGroup.RecalculateBounds();
            }
        }
    }

    GameObject GenerateChunk(Vector3 chunkSize, Vector2 uvStart, Vector2 uvEnd, ChunkLODSetting setting, int lodLv)
    {
        GameObject chunkObject = new GameObject("LOD_" + lodLv);
        MeshFilter chunkMeshFilter = chunkObject.AddComponent<MeshFilter>();
        MeshRenderer chunkMeshRenderer = chunkObject.AddComponent<MeshRenderer>();

        // 渲染设置
        chunkMeshRenderer.shadowCastingMode = setting.RenderSettings.shadowCastingMode;
        chunkMeshRenderer.receiveShadows = setting.RenderSettings.ReceiveShadows;
        //chunkMeshRenderer.allowOcclusionWhenDynamic = setting.RenderSettings.DynamicOccluded;

        Mesh mesh = MeshUtils.GeneratePlane(Vector3.zero,
            Vector3.right * chunkSize.x,
            Vector3.forward * chunkSize.z,
            setting.Size,
            setting.Size,
            uvStart, 
            uvEnd);

        mesh.bounds = new Bounds(0.5f * chunkSize, chunkSize);
        mesh.name = chunkObject.name;
        chunkMeshFilter.mesh = mesh;
        chunkMeshRenderer.materials = Materials;


        m_Ms.sharedMesh = mesh;

        return chunkObject;

    }
}
