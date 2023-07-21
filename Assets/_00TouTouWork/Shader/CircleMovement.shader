Shader "Unlit/CircleMovement"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color("Color Property",Color) = (1,0,0,1)
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent"}
        LOD 100

        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                v.vertex.x += 4*cos(_Time * 50);
                v.vertex.z += 4*sin(_Time * 50);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                //fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                fixed col_r = max(sin(_Time*10 * 6.28),0);
                fixed col_g = max(sin(_Time*10 * 6.28 + 2.09),0);
                fixed col_b = max(sin(_Time*10 * 6.28 + 4.19),0);
                fixed min = 0;
                if (col_r > col_g && col_b > col_g) {
                    col_g = 0;
                }
                if (col_g > col_r && col_b > col_r) {
                    col_r = 0;
                }
                if (col_r > col_b && col_g > col_b) {
                    col_b = 0;
                }

                UNITY_APPLY_FOG(i.fogCoord, col);
                fixed4 col = fixed4(col_r, col_g, col_b, _Color.a);
                return col;
            }
            ENDCG
        }
    }
}
