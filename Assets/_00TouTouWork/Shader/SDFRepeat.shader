Shader "TouTou/SDFRepeat"
{
	SubShader
	{
		Tags { "RenderType"="Opaque" "LightMode"="ForwardBase" }
		LOD 100
		Cull front

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

			float sphereSDF(float3 p, float3 center, float r)
			{
				return length(p-center)-r;
			}

			// n:法線, s:原点と平面の距離
			float planeSDF(float3 p, float3 n, float s)
			{
				return dot(normalize(n),p)-s;
			}

			// 正八面体のSDF
			float octaSDF(float3 p, float s)//s : 正八面体のサイズ
			{
				return planeSDF(abs(p),float3(1.0,1.0,1.0),s);
			}
			
			// 滑らかなmin関数
			float smin(float a, float b, float k)
			{
				float h = clamp(0.5+0.5*(b-a)/k,0,1);
				return lerp(b,a,h) - k*h*(1-h);
			}

			// シーンのSDF
			float sceneSDF(float3 p)
			{
				float3 center = float3(0,0,0);
				float scale= 0.1;
				float3 sphere = sphereSDF(frac(p+0.5)-0.5,center,scale*(1 + sin(_Time.z)*0.5));
				float3 octa = octaSDF(frac(p+0.5)-0.5,scale);
				return max(-sphere,octa);
			}

			// 法線ベクトルを求める
			float3 getNoraml(float3 p)
			{
				float3 n = float3(0,0,0);
				float d = 0.001;
				n.x = sceneSDF(p+float3(d,0,0)) - sceneSDF(p-float3(d,0,0));
				n.y = sceneSDF(p+float3(0,d,0)) - sceneSDF(p-float3(0,d,0));
				n.z = sceneSDF(p+float3(0,0,d)) - sceneSDF(p-float3(0,0,d));
				return normalize(n);
			}

			// フラグメントシェーダー
			float4 frag(v2f i) : SV_Target
			{
				float time =  _Time.x*3;
				float thread = 0.0001;
				float3 ro = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos,1)).xyz ;//レイのスタート位置をカメラのローカル座標とする
				ro += float3(0,0,0);
				float3 rd = normalize(i.pos.xyz - ro);//メッシュのローカル座標の、視点のローカル座標からの方向を求めることでレイの方向を定義
				
				float t=0;
				float d=0;
				float3 p = float3(0,0,0);

                // 球をZ軸方向にアニメーションさせる
                // float3 animatedSphereCenter = float3(sin(_Time.z*2)*0.2, cos(_Time.z*2)*.2, _Time.y);
				float3 animatedSphereCenter = float3(0.5,0.5,-time);
			
				for (int i=0 ; i < 64 ; ++i)
				{
					p = ro + rd * t;
					d = sceneSDF(p-animatedSphereCenter);
					if (d < thread) break;
					t += d;
					
				}
				float4 col = float4(0,0,0,1);
				// レイが衝突していなければ黒
				if(d>thread)
				{
					float fog = exp(-t*0.12);// distance fog ref. [20211210_distance fog](https://www.shadertoy.com/view/NtdSD4)
					col = lerp(float4(0.1,0.1,0.3,1),float4(0,0,0,1),fog);//左がfogの色、右が背景色
				}else
				{
					float3 normal = getNoraml(p-animatedSphereCenter);
					float3 lightDir = normalize(mul(unity_WorldToObject,_WorldSpaceLightPos0).xyz);
					float NdotL = max(0,dot(normal,lightDir));// ランパート反射を計算

					float3 baseCol = float3(0.1,0.5,1);
					col = float4(p*0.6,0)+float4(baseCol*NdotL*9,1);
				}
				return col;
			}
			ENDCG
		}
	}
}