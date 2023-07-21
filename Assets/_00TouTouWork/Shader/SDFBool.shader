Shader "TouTou/SDFBool"
{
	SubShader
	{
		Tags { "RenderType"="Opaque" "LightMode"="ForwardBase" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			// 頂点シェーダー
			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv: TEXCOORD0;
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

			float sphere(float3 p, float3 center, float r)
			{
				return length(p-center)-r;
			}
			
			// 滑らかなmin関数
			float smin(float a, float b, float k)
			{
				float h = clamp(0.5+0.5*(b-a)/k,0,1);
				return lerp(b,a,h) - k*h*(1-h);
			}
			
			// 3次元パーリンノイズ
			float noise(float3 p)
			{
				float3 i = floor(p);
				float3 f = frac(p);
				f = f*f*(3-2*f);
				float a = dot(i,float3(1,57,113));
				float b = dot(i+float3(1,0,0),float3(1,57,113));
				float c = dot(i+float3(0,1,0),float3(1,57,113));
				float d = dot(i+float3(0,0,1),float3(1,57,113));
				return lerp(lerp(lerp(a,b,f.x),lerp(c,d,f.x),f.y),lerp(lerp(a,b,f.x),lerp(c,d,f.x),f.y),f.z);
			}

			// シーンのSDF
			float sceneSDF(float3 p)
			{
				float smallS[3];
				float bigS[3];
				float intervalDist = 2;
				for(int i=0; i<3; i++)
				{
					smallS[i] = sphere(p, float3(i/intervalDist-1/intervalDist,0.1*sin(_Time.y),0), 0.05);
					bigS[i] = sphere(p, float3(i/intervalDist-1/intervalDist,0,0), 0.1);
				}
				float cap = max(smallS[0],bigS[0]);// 共通部分
				float cup = smin(smallS[1],bigS[1],0.01);// 和集合
				float minus = max(smallS[2],-bigS[2]);// 差集合
				return min(min(cap,cup),minus);//全ての和集合
				//return min(min(bigS[0],bigS[1]),bigS[2]);//全ての和集合
			}

			// 法線ベクトルを求める
			float3 getNoraml(float3 p)
			{
				float3 n = float3(0,0,0);
				float d = 0.01;
				n.x = sceneSDF(p+float3(d,0,0)) - sceneSDF(p-float3(d,0,0));
				n.y = sceneSDF(p+float3(0,d,0)) - sceneSDF(p-float3(0,d,0));
				n.z = sceneSDF(p+float3(0,0,d)) - sceneSDF(p-float3(0,0,d));
				return normalize(n);
			}
			
			float sdf(float3 p)
			{
				float d1 = sphere(p,0,0.5);
				return d1;
			}

			// フラグメントシェーダー
			float4 frag(v2f i) : SV_Target
			{
				
				float thread = 0.01;
				float3 ro = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos,1)).xyz;//レイのスタート位置をカメラのローカル座標とする
				float3 rd = normalize(i.pos.xyz - ro);//メッシュのローカル座標の、視点のローカル座標からの方向を求めることでレイの方向を定義
				
				float t=0;
				float d=0;
				float3 p = float3(0,0,0);
				
				for (int i=0 ; i < 64 ; ++i)
				{
					p = ro + rd * t;
					d = sceneSDF(p);
					t += d;
					
				}
				float4 col = float4(0,0,0,1);
				// レイが衝突していなければ黒
				if(d>thread)
				{
					discard;
					col = float4(0,0,0,1);
				}else
				{
					float3 normal = getNoraml(p);
					float3 lightDir = normalize(mul(unity_WorldToObject,_WorldSpaceLightPos0).xyz);
					float NdotL = max(0,dot(normal,lightDir));// ランパート反射を計算
						
					col = float4(float3(0.1,0.5,1)*NdotL*3,1);
				}
				return col;
			}
			ENDCG
		}
	}
}