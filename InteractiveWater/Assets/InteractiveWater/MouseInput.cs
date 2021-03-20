using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MouseInput : MonoBehaviour
{
    private Camera m_Camera;
    private RaycastHit m_HitInfo;

    private void Awake()
    {
        m_Camera = Camera.main;
    }

    private void Update()
    {
        if (Input.GetMouseButtonDown(0))
        {
            Ray ray = m_Camera.ScreenPointToRay(Input.mousePosition);

            if (Physics.Raycast(ray, out m_HitInfo))
            {
                Ball ball = m_HitInfo.transform.GetComponent<Ball>();
                if (ball != null)
                {
                    ball.OnClicked(m_HitInfo.point);
                }
            }
        }
    }
}
