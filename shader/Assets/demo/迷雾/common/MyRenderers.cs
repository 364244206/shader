using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MyRenderers : MonoBehaviour
{
    private Transform m_transform;
    private float m_checkTime;
    private float m_checkMaxTime = 0.5f;

    public void Start()
    {
        m_transform = transform;
    }

    public void Update()
    {
        m_checkTime += Time.deltaTime;
        if (m_checkTime > m_checkMaxTime)
        {
            m_checkTime = 0;
            CheckVisible();
        }
    }

    public void CheckVisible()
    {
        if (FowSys.instance == null)
            return;

        if (FowSys.instance.IsVisible(m_transform.position))
        {
            m_transform.localScale = Vector3.one;
        }
        else
        {
            m_transform.localScale = Vector3.zero;
        }
    }
}