using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//Buffer数据结构
struct PBuffer
{
    //size 40
    public float life;//4
    public Vector3 pos;//4x3
    public Vector3 scale;//4x3
    public Vector3 eulerAngle;//4x3
};

public class BuffDemo : MonoBehaviour
{
    public ComputeShader shader;
    public GameObject prefab;

    public List<GameObject> pool = new List<GameObject>();
    int count = 16;
    private ComputeBuffer buffer;

    // Start is called before the first frame update
    void Start()
    {
        for(int i = 0; i < count; i ++)
        {
            GameObject obj = Instantiate(prefab) as GameObject;
            pool.Add(obj);
        }
        CreateBuffer();
    }

    private void CreateBuffer()
    {
        // 数组长度，字节长度
        buffer = new ComputeBuffer(count, 40);
        PBuffer[] values = new PBuffer[count];
        for(int i = 0; i < count; i ++)
        {
            PBuffer m = new PBuffer();
            InitStruct(ref m);
            values[i] = m;
        }
        buffer.SetData(values);
    }

    private void Update()
    {
        shader.SetFloat("deltaTime", Time.deltaTime);
        int kid = shader.FindKernel("CSMain");
        shader.SetBuffer(kid, "buffer", buffer);
        shader.Dispatch(kid, 2, 2, 1);

        // 根据shader返回的buffer数据更新物体信息
        PBuffer[] values = new PBuffer[count];
        buffer.GetData(values);
        bool reborn = false;
        for (int i = 0; i < count; i++)
        {
            if (values[i].life < 0)
            {
                InitStruct(ref values[i]);
                reborn = true;
            }
            else
            {
                pool[i].transform.position = values[i].pos;
                pool[i].transform.localScale = values[i].scale;
                pool[i].transform.eulerAngles = values[i].eulerAngle;
                //pool [i].GetComponent<</span>MeshRenderer>().material.SetColor ("_TintColor", new Color(1,1,1,values [i].life));
            }
        }
        if (reborn)
            buffer.SetData(values);

    }


    void InitStruct(ref PBuffer m)
    {
        m.life = Random.Range(1f, 3f);
        m.pos = Random.insideUnitSphere * 5f;
        m.scale = Vector3.one * Random.Range(0.3f, 1f);
        m.eulerAngle = new Vector3(0, Random.Range(0f, 180f), 0);
    }


    void ReleaseBuffer()
    {
        buffer.Release();
    }
    private void OnDisable()
    {
        ReleaseBuffer();
    }
}
