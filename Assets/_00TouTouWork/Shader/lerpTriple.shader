Shader "TouTou/lerpTriple"
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

			// 頂点シェーダー
			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv: TEXCOORD0;
				float4 color : COLOR;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float4 color : COLOR;
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				o.color = v.color;
				return o;
			}

			// フラグメントシェーダー
			float4 frag(v2f i) : COLOR
			{
				i.uv.xy *=3;
				float a = frac(_Time.x * 10)*3;
				//float a = 3;
				if(i.uv.x>=a)
				{
					i.uv.x -= a;
				}
				else
				{
					i.uv.x += 3-a;
				}
				if(i.uv.y>=a)
				{
					i.uv.y -= a;
				}
				else
				{
					i.uv.y += 3-a;
				}
				int indx = floor(i.uv.x);
				int indy = floor(i.uv.y);
				float4 array[3];
				array[0] = float4(1,0,0,1);
				array[1] = float4(0,1,0,1);
				array[2] = float4(0,0,1,1);
				float4 cx = array[indx%3]*(1-frac(i.uv.x)) + array[(indx+1)%3]*(frac(i.uv.x));
				float4 cy = array[indy%3]*(1-frac(i.uv.y)) + array[(indy+1)%3]*(frac(i.uv.y));
				return cx*(1+sin(_Time.y))+cy*(1-sin(_Time.y));
			}

			
			ENDCG
		}
	}
}