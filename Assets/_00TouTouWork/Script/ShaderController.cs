using UnityEngine;

namespace TouTouWork.Script
{
    public class ShaderController : MonoBehaviour
    {
        private void Start()
        {
            GetComponent<Renderer>().material.SetColor("_BaseColor",Color.black);
        }
    }
}