using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MyRevealer : MonoBehaviour
{
    public float m_sightHeight = 2;
    /// <summary>
    /// 探测范围
    /// </summary>
    public float range = 0f;
    public Vector3 m_curPos;
    private Transform m_transform;

    public void Start()
    {
        m_transform = transform;
        UpdatePos();
    }

    public void Update()
    {
        UpdatePos();
    }

    public void UpdatePos()
    {
        m_curPos = m_transform.position;
    }
}