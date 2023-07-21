// ref
// [ボロノイ図とその３つの性質 | 高校数学の美しい物語](https://manabitimes.jp/math/1194)
// [The Book of Shaders: More noise](https://thebookofshaders.com/12/?lan=jp)
// [ボロノイ領域：2D - jmatudaの技術メモ](https://sites.google.com/site/jmatuda/math/boronoi-2d)
Shader "TouTou/VoronoiFeatureRaymarching"
{
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100
		Cull front

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
				float3 pos : TEXCOORD1;
				float4 vertex : SV_POSITION;
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.pos = v.vertex.xyz;// メッシュのローカル座標
				o.uv = v.uv;
				return o;
			}

			float3 random3(float3 st)
			{
				st = float3(dot(st, float3(127.1, 311.7, 74.7)),
                            dot(st, float3(269.5, 183.3, 246.1)),
                            dot(st, float3(419.2, 371.9, 217.7)));
				return -1.0 + 2.0 * frac(sin(st) * 43758.5453);
			}

			float sphere(float3 p,float3 centor, float r) //球の距離関数
			{
				return length(p - centor) - r;
			}

			// 点aと点bを結ぶ太さrの線分の距離関数
			float lineSegment(float3 p,float3 a, float3 b ,float r)
			{
				float3 pa = p - a;
				float3 ba = b-a;
				float h = clamp(dot(pa,ba)/dot(ba,ba),0.0,1.0);
				return length(pa - ba*h) - r;
			}

			// 繰り返し、rは繰り返しの間隔
			float3 trans(float3 p,float r)
			{
				return fmod(p,r)-r/2.0;
			}

			float cubesSDF(float3 p, float3 size)
			{
				p = abs(p);
				float3 e = trans(p,1) ;
				return length(max(abs(e) - size, 0.0)) ;
			}

			float cylinderesSDF(float3 p , float r)
			{
				p = abs(p);
				float3 e = trans(p,1);
				float x = length(e.yz) - r;
				float y = length(e.xz) - r;
				float z = length(e.xy) - r;
				return min(min(x,y),z);
			}

			// gridの距離関数
			// TODO: modで繰り返してGridをだす, repeatation
			float grid(float3 p)
			{
				float r = 0.005;
				float m = 1.732;
				// 四角柱を描画 (綺麗に表示される)
				// float mx = cubesSDF(p,float3(1,r,r));
				// float my = cubesSDF(p,float3(r,1,r));
				// float mz = cubesSDF(p,float3(r,r,1));
				// m = min(min(mx,my),mz);
				// return m;
				return cylinderesSDF(p,r);
			}
			
			// 一番近い母点をもとめる
			float3 voronoi(float3 p)
			{
				float3 ist = floor(p);
				float3 fst = frac(p);
				float3 min_point = float3(0.5,0.5,0.5);
				float min_dist = sqrt(3);
				for(int x=-1;x<=1;x++)
				{
					for(int y=-1;y<=1;y++)
					{
						for(int z=-1;z<=1;z++)
						{
							// 近隣の格子点
							float3 neighbor = float3(x,y,z);
							// 近隣の母点
							float3 mother = neighbor  + (0.5) * sin(_Time.y+0.5+6.2831*random3(ist + neighbor));
							float dist = length(mother - fst);
							if(dist < min_dist)
							{
								min_dist = dist;
								min_point = ist+mother;
							}
						}
					}
				}
				return min_point;
			}

			float sdf(float3 p)
			{
				float d1 = sphere(p,voronoi(p),0.05);
				float d2 = grid(p);
				return min(d1,d2);
			}
			
			float4 frag(v2f i):COLOR
			{
				float thred = 0.0001;
				float3 ro = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos,1)).xyz;// レイのスタート位置をカメラのローカル座標とする
				float3 rd = normalize(i.pos.xyz - ro);// レイの方向をレイのスタート位置からメッシュのローカル座標へのベクトルとする
				float2 uv = i.uv;
				// ボロノイ用の格子
				
				float d=0;
				float t=0;
				float3 p=float3(0,0,0);
				int coli=0;
				for (int i = 0; i < 128; ++i) { //レイマーチングのループを実行
					p = ro + rd * t;
					d = sdf(p);
					// レイの進んだ回数を色とする
					if(d < thred)
					{
						coli = i;
						break;
					}
					t += d;
				}

				float4 col = float4(0,0,0,1);
				if (d > thred) { //レイが衝突していないと判断すれば黒に描画する
					//discard;
					float fog = exp(-t*0.12);// distance fog ref. [20211210_distance fog](https://www.shadertoy.com/view/NtdSD4)
					col = lerp(float4(0.1,0.1,0.3,1),float4(0,0,0,1),fog);//左がfogの色、右が背景色
				}
				else {
					float fog = exp(-t*0.12);// distance fog ref. [20211210_distance fog](https://www.shadertoy.com/view/NtdSD4)
					//col = float4(1,1,1,1)*(1-depth);////レイが衝突していれば白に描画する
					//col = float4(0,1,1,1)*fog;
					col = lerp(float4(0.1,0.1,0.3,1),float4(1,1,1,1),fog);
				}
				return col;
			}
			ENDCG
		}
	}
}