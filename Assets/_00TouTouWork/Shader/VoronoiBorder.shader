Shader "TouTou/VoronoiBorder"
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
            
            float2 voronoiDistance(float2 st)
			{
				float size = 10;
				st =st*size;
				// Voronoi
				float2 ist = floor(st);
				float2 fst = frac(st);

				float min_d = sqrt(2);
				float2 mn = float2(0,0);
				float2 mp = float2(0.5,0.5);
				for(int k=-1;k<=1;k++)
				{
					for(int j=-1;j<=1;j++)
					{
						// 近隣の格子点
						float2 neighbor = float2(k,j);
						//　近隣の母点
						float2 m = neighbor + 0.5 +  0.5*sin(_Time.y + 6.2831 * random2(ist+ neighbor));//　格子全体で隣接する母点のシード値をそろえる
						// ある座標からある近隣の母点への距離
						// 格子座標は打ち消し合うので、整数部分はそぎ落として、精度を上げる
						float d = length(m-fst);
						if(d<min_d)
						{
							min_d = d;
							mp = m;
							mn = neighbor;
						}							
						
					}
				}

				// 二番目に近い母点を見つける
				float2 mp2 = float2(0.5,0.5);
				float min_dm12 = 10;
				for (int k = -2; k < 2; k++)
				{
					for(int j=-2; j< 2; j++)
					{
						// 近隣の格子点
						float2 neighbor = float2(k,j);
						//　近隣の母点
						float2 mp2 = neighbor + 0.5 +  0.5*sin(_Time.y + 6.2831 * random2(ist+ neighbor));//　格子全体で隣接する母点のシード値をそろえる
						float2 m12 = mp2 - mp;
						if(length(m12) > 0.001)
						{
							float dm12 = dot((mp+mp2)*0.5-fst,normalize(m12));
							min_dm12 = min(min_dm12,dm12);
						}
					}
				}

				return float2(min_dm12,min_d);
			}

			
			float borderFeature( float2 p )
			{
				float border = voronoiDistance( p ).x;
				float feature = voronoiDistance( p ).y;
				return 1.0 - smoothstep(0.0,0.05,border) + 1- smoothstep(0.0,0.05,feature);
			}
			


			float4 frag(v2f i):COLOR
			{
				
				// mp(母点)から最も近い母点を探す
				
				float min_d = borderFeature(i.uv);
				return float4(min_d,min_d,0,1);
			}
			
			ENDCG
		}
	}
}