Shader "TouTou/Minkowski"
{
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert(appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float2 random2(float2 st) {
                st = float2(dot(st, float2(127.1, 311.7)),
                            dot(st, float2(269.5, 183.3)));
                return -1.0 + 2.0 * frac(sin(st) * 43758.5453123);
            }

            float voronoi(float2 p) {
                float2 neighbor, mother;
                float2 ist = floor(p);
                float2 fst = frac(p);
                float u_time = _Time.x*5;
                float minDist = sqrt(2.);
                float minDist2 = sqrt(2.);
                float dist;

                for (int k = -1; k <= 1; k++) {
                    for (int j = -1; j <= 1; j++) {
                        neighbor = float2(k, j);
                        mother = neighbor + 0.5 +  0.5 * sin(u_time + 6.2831 * random2(ist + neighbor));
                        float2 relative = mother - fst;
                        float n = 10. * sin(u_time);
                        float2 S = pow(abs(relative), float2(n, n));
                        dist = pow(S.x + S.y, 1. / n);

                        if (dist < minDist) {
                            minDist = dist;
                        } else if (dist < minDist2) {
                            minDist2 = dist;
                        }
                    }
                }

                float diff = minDist2 - minDist;
                return 1. - step(.04, diff);
            }

            fixed4 frag(v2f i) : SV_Target {
                float2 uv = i.uv;
                uv *= 10.;
                float dist = voronoi(uv);
                return fixed4(dist, dist, dist, 1.0);
            }
            ENDCG
        }
	}
}