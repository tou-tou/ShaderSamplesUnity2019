Shader "TouTou/GeoRepeatBox"
{
	SubShader
	{
		Cull Off
		Pass
		{
			Tags { "RenderType"="Opaque" }
			CGPROGRAM
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};
			
			struct g2f
			{
				float4 vertex: SV_POSITION;
				float2 uv: TEXCOORD0;
			};

			appdata vert(appdata v)
			{
				return v;
			}
			
			[maxvertexcount(3)]
			void geom(triangle appdata input[3],inout TriangleStream<g2f> stream)
			{
				// 法線を計算
				float3 normal = normalize(cross(input[1].vertex.xyz - input[0].vertex.xyz, input[2].vertex.xyz - input[0].vertex.xyz));
				[unroll]
				for (int i = 0; i < 3; ++i)
				{
					appdata v = input[i];
					g2f o;
					// 法線ベクトル方向に頂点を移動
					v.vertex.xyz += normal * (cos(_Time.y*3+ UNITY_PI )-1.0)*0.25;
					o.vertex = UnityObjectToClipPos(v.vertex);
					o.uv = v.uv;
					stream.Append(o);
				}
			}
			
			float wave(float2 st, float n)
			{
			 st = (floor(st * n) + 0.5) / n;
			 float d = distance(0.5, st);
			 return (1 + sin(d * 5 - _Time.y * 3)) * 0.5;
			}

		
			float box(float2 st,float size)
			{
				size = 0.5 + size * 0.5;
				// y = step(threshold, x)
				float stx = step(1-size,st.x)*(1-step(size,st.x));
				float sty = step(1-size,st.y)*(1-step(size,st.y));
				return stx*sty;
			}

			float4 frag(g2f i): COLOR
			{
				float2 uv = i.uv;
				float n = 10;
				float2 st = frac(uv*n);
				float size1 = wave(i.uv,3);
				float size2 = wave(i.uv,7);
				float size3 = wave(i.uv,11);
				//return float4(box(st,abs(sin(_Time.y*1.5))),1,1,1);
				return float4(box(st,size1),box(st,size2),box(st,size3),1);
			}
			ENDCG
		}
	}
}