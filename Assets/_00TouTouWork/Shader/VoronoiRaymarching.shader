// ref
// [ボロノイ図とその３つの性質 | 高校数学の美しい物語](https://manabitimes.jp/math/1194)
// [The Book of Shaders: More noise](https://thebookofshaders.com/12/?lan=jp)
// [ボロノイ領域：2D - jmatudaの技術メモ](https://sites.google.com/site/jmatuda/math/boronoi-2d)
Shader "TouTou/VoronoiRaymarching"
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

			

			float sphere(float3 p,float3 center, float r) //球の距離関数
			{
				return length(p - center) - r;
			}

			float3 getNormal(float3 p,float3 center,float r)
			{
				float d = 0.01;
				return normalize(float3(
					sphere(p + float3(d, 0, 0),center,r) - sphere(p - float3(-d, 0, 0),center,r),
					sphere(p + float3(0, d, 0),center,r) - sphere(p - float3(0, -d, 0),center,r),
					sphere(p + float3(0, 0, d),center,r) - sphere(p - float3(0, 0, -d),center,r)
				));
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

			float plane(float3 p, float r)
			{
				p = abs(p);
				p = trans(p,1);
				return p.x - r;
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
				// float3 ab = b - a;
				// float3 ac = c - a;
				// float3 bc = c - b;
				// float3 n = cross(ab, ac);
				// float3 n2 = cross(ab, n);
				// float3 n3 = cross(ac, n);
				// float3 n4 = cross(bc, n);
				// float3 p = (n2 * dot(n2, n3) + n3 * dot(n3, n2)) / (2 * dot(n2, n3));
				// return a + p;
				float e1 = pow(abs(length(b-c)),2);
				float e2 = pow(abs(length(c-a)),2);
				float e3 = pow(abs(length(a-b)),2);
				float3 vu = e1*(e2+e3-e1)*a + e2*(e3+e1-e2)*b + e3*(e1+e2-e3)*c;
				float vd = e1*(e2+e3-e1) + e2*(e3+e1-e2) + e3*(e1+e2-e3);
				float3 min_v = vu/vd;
				return min_v;
			}

			// 外接球の中心を求める
			float3 circumSphereCenter(float3 a,float3 b, float3 c, float3 d)
			{
				float3 v1 = circumCenter(a,b,c);
				float3 v2 = circumCenter(a,b,d);
				float3 n1 = normalize(cross(b-a,c-a));
				float3 n2 = normalize(cross(b-a,d-a));
				// l1 : sn + v1, l2 : tn + v2
				// 逆行列で解く
				float2x2 ai =  1/(n1.x*(-n2.y) - (-n2.x*n1.y))*float2x2(-n2.y,n2.x,-n1.y,n1.x);
				float2 st = mul(ai,float2x1(v2.xy-v1.xy));
				return st.x*n1 + v1;
			}
			
			// 一番近い母点をもとめる
			float4 voronoi(float3 p)
			{
				float time = _Time.y*0.5;
				float3 ist = floor(p);
				float3 fst = frac(p);
				float3 mp1 = float3(0.5,0.5,0.5);
				float min_dist = sqrt(3);
				for(int x=-1;x<=1;x++)
				{
					for(int y=-1;y<=1;y++)
					{
						for(int z=-1;z<=1;z++)
						{
							// 近隣の格子点
							float3 neighbor1 = float3(x,y,z);
							// 近隣の母点
							//float3 mother = neighbor + 0.5/size;
							float3 mother1 = neighbor1 + (0.5) + (0.5) * sin(time+6.2831*random3(ist + neighbor1));
							float dist = length(mother1 - fst);
							if(dist < min_dist)
							{
								min_dist = dist;
								mp1 = mother1;
							}
						}
					}
				}

				// 二番目に近い母点を見つける
				float3 mp2 = float3(0.5,0.5,0.5);
				float min_dm12 = 10;
				for (int k = -1; k <= 1; k++)
				{
					for(int j=-1; j<= 1; j++)
					{
						for(int l =-1 ; l <= 1 ; l++)
						{
							// 近隣の格子点
							float3 neighbor2 = float3(k,j,l);
							//　近隣の母点
							float3 mother2 = neighbor2 + 0.5 +  0.5*sin(time + 6.2831 * random3(ist+ neighbor2));//　格子全体で隣接する母点のシード値をそろえる
							float3 m12 = mother2 - mp1;
							if(length(m12) < 0.001)
							{
								continue;
							}
							// 二つの母点の垂直二等分平面との距離
							float dm12 = dot((mp1+mother2)*0.5-fst,normalize(m12));
							if (abs(dm12) < min_dm12)
							{
								min_dm12 = abs(dm12);
								mp2 = mother2;
							}
						}
					}
				}
				
				return float4(mp1+ist,smoothstep(0,0.04,min_dm12));
			}

			float4 dfs(float3 p)
			{
				float4 v = voronoi(p);
				float d1 = sphere(p,v.xyz,0.02);
				//float d2 = grid(p);
				float d2 = v.w;
				float d3 = plane(p,0.01);
				 if(d1 < d2)
				 {
				 	return float4(v.xyz,d1);
				 }
				 else
				 {
				 	return float4(float3(100,100,100),d2);
				 }
				 return float4(v.xyz,min(d1,d2));
				return float4(v.xyz,d2);
				//return d3;
				//return d2;
				
			}
			
			float4 frag(v2f i):COLOR
			{
				float thred = 0.001;
				float3 ro = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos,1)).xyz;// レイのスタート位置をカメラのローカル座標とする
				float3 rd = normalize(i.pos.xyz - ro);// レイの方向をレイのスタート位置からメッシュのローカル座標へのベクトルとする
				// ボロノイ用の格子
				
				float d=0;
				float t=0;
				float3 v;
				float3 p=float3(0,0,0);
				int coli=0;
				for (int i = 0; i < 9; ++i) { //レイマーチングのループを実行
					p = ro + rd * t;
					float4 vd = dfs(p);
					v = vd.xyz;
					d = vd.w;
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
					//col = float4(0,0,0,1);
				}
				else {
					float fog = exp(-t*0.15);// distance fog ref. [20211210_distance fog](https://www.shadertoy.com/view/NtdSD4)
					//col = float4(1,1,1,1)*(1-depth);////レイが衝突していれば白に描画する
					//col = float4(0,1,1,1)*fog;
					col = lerp(float4(0.1,0.1,0.3,1),float4(1,1,1,1),fog);
					//col = float4(1,1,1,1);
					//float3 normal = getNormal(p,v.xyz,0.03);
					//float3 lightdir = normalize(mul(unity_WorldToObject, _WorldSpaceLightPos0).xyz);//ローカル座標で計算しているので、ディレクショナルライトの角度もローカル座標にする
					//float NdotL = max(0, dot(normal, lightdir));// ランパート反射を計算
					//col = float4(float3(1,1,1)*NdotL,1);
				}
				return col;
			}
			ENDCG
		}
	}
}