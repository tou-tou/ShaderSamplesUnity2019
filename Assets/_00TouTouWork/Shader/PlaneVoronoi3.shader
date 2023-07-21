Shader "TouTou/PlaneVoronoi3"
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
				int size = 7;
				i.uv =i.uv*size;
				// Voronoi
				float2 ist = floor(i.uv);
				float2 fst = frac(i.uv);

				float md = sqrt(2);
				float2 mp = float2(0.5,0.5);
				for(int k=-1;k<=1;k++)
				{
					for(int j=-1;j<=1;j++)
					{
						// 近隣の格子点
						float2 neighbor = float2(k,j);
						//　近隣の母点
						float2 m = neighbor + 0.5 +0.5*sin(_Time.y + 6.2831*random2(ist+neighbor));//　格子全体で隣接する母点のシード値をそろえる
						// ある座標からある近隣の母点への距離
						// 格子座標は打ち消し合うので、整数部分はそぎ落として、精度を上げる
						float d = length(m-fst);
						if(d < md)
						{
							// keep the closer distance
							md =d;
							// keep the position of the closer point
							mp=ist+m;
						}
					}
				}
				
				float4 col = md*1.5;
				col.xy =mp*0.1;
				col.xy += (size-mp)*0.02;
				// show isolines
				col -= abs(-sin(md*60))*0.5;
				// draw cell center
				col += 1-step(0.02,md);
				col.z = 0.4;
				return col;
			}
			
			ENDCG
		}
	}
}