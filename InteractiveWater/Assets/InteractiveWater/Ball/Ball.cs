using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Ball : MonoBehaviour
{
    private Rigidbody m_Rigidbody = null;

    private void Awake()
    {
        m_Rigidbody = GetComponent<Rigidbody>();    
    }

    public void OnClicked(Vector3 clickPos)
    {
        //Vector2 randomDir = UnityEngine.Random.insideUnitCircle;
        //Vector3 dir = new Vector3(randomDir.x, 0, randomDir.y).normalized;
        Vector3 dir = transform.position - clickPos;
        dir.y = 0;
        dir = dir.normalized;

        m_Rigidbody.AddForce(dir * 10, ForceMode.Impulse);
    }
}
