Shader "TouTou/RepeatBox"
{
	SubShader
	{

		Pass
		{
			Tags { "RenderType"="Opaque" }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct v2f
			{
				float4 pos: SV_POSITION;
				float2 uv: TEXCOORD0;
			};

			v2f vert(appdata_base v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord;
				return o;
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

			float4 frag(v2f i): COLOR
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