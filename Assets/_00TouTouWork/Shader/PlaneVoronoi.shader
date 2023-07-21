Shader "TouTou/PlaneVoronoi"
{
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}

			float rand(float x)
			{
				return frac(sin(x) * 43758.5453123);
			}

			float2 random2(float2 st)
            {
                st = float2(dot(st, float2(127.1, 311.7)),
                            dot(st, float2(269.5, 183.3)));
                return -1.0 + 2.0 * frac(sin(st) * 43758.5453123);
            }

			float4 frag(v2f i):COLOR
			{
				i.uv =i.uv*10;
				
				
				// Voronoi
				float2 ist = floor(i.uv);
				float2 fst = frac(i.uv);

				float md = sqrt(2);
				for(int k=-1;k<=1;k++)
				{
					for(int j=-1;j<=1;j++)
					{
						// 近隣の格子点
						float2 neighbor = ist + float2(k,j);
						//　近隣の母点
						float2 m = neighbor + 0.5 +  0.5*sin(_Time + 6.2831 * random2(neighbor));//　隣接する母点のシード値をそろえる
						// ある座標からある近隣の母点への距離
						float d = length(i.uv -m);
						md = min(md,d);
					}
				}
				return float4(md,md,md,1);
			}
			
			ENDCG
		}
	}
}