using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Main : MonoBehaviour
{
    private FowSys m_fowSys;
    public MyRevealer[] m_revealer;

    void Start()
    {
        m_fowSys = GetComponent<FowSys>();
        m_fowSys.Init();

        for (int i = 0; i < m_revealer.Length; i++)
        {
            m_fowSys.AddRev(m_revealer[i]);
        }
    }

    void Update()
    {
        float h = Input.GetAxis("Horizontal");
        float v = Input.GetAxis("Vertical");
        Vector2 dir = new Vector2(h, v);
        if (dir != Vector2.zero)
        {
            m_revealer[0].transform.position += new Vector3(dir.x, 0, dir.y) * Time.deltaTime * 4;
        }
    }
}