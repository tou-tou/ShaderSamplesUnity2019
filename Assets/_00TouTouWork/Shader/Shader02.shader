Shader "TouTou/Shader02" {
	SubShader 
	{
		Pass{
			
			Tags { "RenderType"="Opaque" }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct v2f
			{
				float4 pos: SV_POSITION;
			};

			v2f vert(appdata_base v)
			{
				v2f o;
				//float4 vert = float4(v.vertex.w * sin(_Time.z),v.vertex.xyz);
				//float4 vert = float4(v.vertex.x,v.vertex.yz * sin(_Time.z),v.vertex.w);
				int r =1;
				float4 vert = float4(v.vertex.x,r*sin(_Time.z)+v.vertex.y * sin(_Time.z),r*cos(_Time.z)+v.vertex.z*sin(_Time.z) ,v.vertex.w);
				o.pos = UnityObjectToClipPos(vert);
				return o;
			}

			half4 frag(v2f i): COLOR
			{
				return half4(0,0.5*cos(-1*_Time.x),0.5+ 0.5*sin(_Time.z),1);
			}
			ENDCG
		}
	}
}