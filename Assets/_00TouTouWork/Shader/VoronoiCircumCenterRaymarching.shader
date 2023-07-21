// ref
// [ボロノイ図とその３つの性質 | 高校数学の美しい物語](https://manabitimes.jp/math/1194)
// [The Book of Shaders: More noise](https://thebookofshaders.com/12/?lan=jp)
// [ボロノイ領域：2D - jmatudaの技術メモ](https://sites.google.com/site/jmatuda/math/boronoi-2d)
// 3Dボロノイので3つの特徴点からつくる三角形の外心を表示する
Shader "TouTou/VoronoiCircumCenterRaymarching"
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
			float grid(float3 p)
			{
				float r = 0.01;
				return cylinderesSDF(p,r);
			}

			// 外心を求める ref https://ja.wikipedia.org/wiki/%E5%A4%96%E6%8E%A5%E5%86%86#%E5%A4%96%E5%BF%83%E3%81%AE%E4%BD%8D%E7%BD%AE
			float3  circumCenter(float3 a, float3 b, float3 c)
			{
				float3 ab = b - a;
				float3 ac = c - a;
				float3 bc = c - b;
				float3 n = cross(ab, ac);
				float3 n2 = cross(ab, n);
				float3 n3 = cross(ac, n);
				float3 n4 = cross(bc, n);
				float3 p = (n2 * dot(n2, n3) + n3 * dot(n3, n2)) / (2 * dot(n2, n3));
				return a + p;
				// float e1 = pow(abs(length(b-c)),2);
				// float e2 = pow(abs(length(c-a)),2);
				// float e3 = pow(abs(length(a-b)),2);
				// float3 vu = e1*(e2+e3-e1)*a + e2*(e3+e1-e2)*b + e3*(e1+e2-e3)*c;
				// float vd = e1*(e2+e3-e1) + e2*(e3+e1-e2) + e3*(e1+e2-e3);
				// float3 min_v = vu/vd;
				// return min_v;
			}
			
			// 一番近い母点をもとめる
			float4 voronoi(float3 p)
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
							//float3 mother = neighbor + 0.5/size;
							float3 mother = neighbor + (0.5) + (0.5) * sin(_Time.y+6.2831*random3(ist + neighbor));
							float dist = length(mother - fst);
							if(dist < min_dist)
							{
								min_dist = dist;
								min_point = mother;
							}
						}
					}
				}

				// 二番目に近い母点を見つける
				float3 mp2 = float3(0.5,0.5,0.5);
				float min_dm12 = 10;
				for (int k = -1; k < 1; k++)
				{
					for(int j=-1; j< 1; j++)
					{
						for(int l =-1 ; l < 1 ; l++)
						{
							// 近隣の格子点
							float3 neighbor = float3(k,j,l);
							//　近隣の母点
							float3 mp2 = neighbor + 0.5 +  0.5*sin(_Time.y + 6.2831 * random3(ist+ neighbor));//　格子全体で隣接する母点のシード値をそろえる
							float3 m12 = mp2 - min_point;
							if(length(m12) > 0.001)
							{
								float dm12 = dot((min_point+mp2)*0.5-fst,normalize(m12));
								min_dm12 = min(min_dm12,dm12);
							}
						}
						
					}
				}
				
				float3 mp1 = min_point;
				// 点pに一番近いボロノイ頂点との距離を求める
				float3 min_v = float3(0,0,0);
				float minvd = 10;
				for(int i = -1; i <=1; i++)
				{
					for(int j = -1; j <= 1; j++)
					{
						for(int k = -1; k <= 1; k++)
						{
							float3 neighbor = float3(i,j,k);
							float3 mp3 = neighbor + 0.5 + 0.5*sin(_Time.y + 6.2831 * random3(ist+neighbor));
							float3 m13 = mp3 - mp1;
							float3 m23 = mp3 - mp2;
							for(int l=-1;l<1;l++)
							{
								for(int m=-1;m<=1;m++)
								{
									for(int n=-1;n<=1;n++)
									{
										// float3 neighbor2 = float3(l,m,n);
										// float3 mp4 = neighbor2 + 0.5 + 0.5*sin(_Time.y + 6.2831 * random3(ist+neighbor2));
										// float3 m14 = mp4 - mp1;
										// float3 m24 = mp4 - mp2;
										// float3 m34 = mp4 - mp3;
										// float3 v = circumcenter(mp1,mp2,mp3,mp4);
										// float vd = dot(v-fst,normalize(m13+m23+m34));
										// if(vd < minvd)
										// {
										// 	minvd = vd;
										// 	min_v = v;
										// }
									}
								}
							}
							// 
								// 外心の位置 
								float3 min_v = circumCenter(mp1,mp2,mp3);
								minvd = min(minvd,length(min_v-fst));
							
						}
					}
				}
				

				
				return float4(min_point+ist,minvd-0.001);
			}

			float dfs(float3 p)
			{
				float4 v = voronoi(p);
				float d1 = sphere(p,v.xyz,0.1);
				//float d2 = grid(p);
				float d2 = v.w;
				//return min(d1,d2);
				return d2;
			}
			
			float4 frag(v2f i):COLOR
			{
				float thred = 0.001;
				float3 ro = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos,1)).xyz;// レイのスタート位置をカメラのローカル座標とする
				float3 rd = normalize(i.pos.xyz - ro);// レイの方向をレイのスタート位置からメッシュのローカル座標へのベクトルとする
				// ボロノイ用の格子
				
				float d=0;
				float t=0;
				float3 p=float3(0,0,0);
				int coli=0;
				for (int i = 0; i < 128; ++i) { //レイマーチングのループを実行
					p = ro + rd * t;
					d = dfs(p);
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
					float fog = exp(-t*0.15);// distance fog ref. [20211210_distance fog](https://www.shadertoy.com/view/NtdSD4)
					col = lerp(float4(0.1,0.1,0.3,1),float4(0,0,0,1),fog);//左がfogの色、右が背景色
					col = float4(0,0,0,1);
				}
				else {
					float fog = exp(-t*0.15);// distance fog ref. [20211210_distance fog](https://www.shadertoy.com/view/NtdSD4)
					//col = float4(1,1,1,1)*(1-depth);////レイが衝突していれば白に描画する
					//col = float4(0,1,1,1)*fog;
					col = lerp(float4(0.1,0.1,0.3,1),float4(1,1,1,1),fog);
					//col = float4(1,1,1,1);
				}
				return col;
			}
			ENDCG
		}
	}
}