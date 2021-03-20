﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class InteractiveShaderRT : MonoBehaviour
{
    [SerializeField]
    private RenderTexture m_RenderTex;
    [SerializeField]
    private Transform m_Target;
    [SerializeField]
    private Camera m_Camera;
    [SerializeField]
    private bool m_ShowRT = false;

    void Awake()
    {
        Shader.SetGlobalTexture("_GlobalEffectRT", m_RenderTex);
        Shader.SetGlobalFloat("_OrthographicCamSize", m_Camera.orthographicSize);
    }

    private void Update()
    {
        transform.position = new Vector3(m_Target.transform.position.x, transform.position.y, m_Target.transform.position.z);
        Shader.SetGlobalVector("_Position", transform.position);
    }

    private void OnGUI()
    {
        if (m_ShowRT)
        {
            GUI.DrawTexture(new Rect(0, 0, 256, 256), m_RenderTex, ScaleMode.ScaleToFit, false, 1);
        }
    }
}
