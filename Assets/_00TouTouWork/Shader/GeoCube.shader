Shader "TouTou/GeoCube"
{
	Properties
	{
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Texture", 2D) = "white" {}
		
		[Space]
		_Glossiness ("Glossiness", Range(0,1)) = 0.5
		[Gamma] _Metallic ("Metallic", Range(0,1)) = 0
		
		[Space]
		_BumpMap ("Bump Map", 2D) = "bump" {}
		_BumpScale ("Bump Scale", Float) = 1
		
		[Space]
		_OcclusionMap ("Occlusion Map", 2D) = "white" {}
		_OcclusionStrength ("Occlusion Strength", Range(0,1)) = 1
		
		[Space]
		_LocalTime ("Local Time", Float) = 0.0
	}
	SubShader
	{
		
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			float _LocalTime;
			struct Attributes
			{
				float4 position: POSITION;
				float3 normal: NORMAL;
				float4 tangent : TANGENT;
				float2 texcoord : TEXCOORD;
			};

			struct Varyings
			{
				float4 position: SV_POSITION;
				float3 normal : NORMAL;
			};

			Attributes vert(Attributes input)
			{
				Attributes output;
				output.position = UnityObjectToClipPos(input.position);
				output.normal = UnityObjectToWorldNormal(input.normal);
				return output;
			}

			[maxvertexcount(15)]
			void geom(triangle Attributes input[3],uint pid: SV_PrimitiveID,inout TriangleStream<Varyings> outStream)
			{
				float3 p1 = input[0].position.xyz;
				float3 p2 = input[1].position.xyz;
				float3 p3 =	input[2].position.xyz;
				//float3 norm = normalize(cross(p2 - p1, p3 - p1));
				float3 norm = normalize(input[0].normal+input[1].normal+input[2].normal);

				float extent = saturate(0.4 - cos(_Time.y * UNITY_PI * 2.0) * 0.4);
				extent = extent*(1+0.3*sin(pid + _Time.y * UNITY_PI * 2.0));
				float3 offset = norm * extent;
				float3 np1 = p1 + offset;
				float3 np2 = p2 + offset;
				float3 np3 = p3 + offset;

				// 続き ref:https://qiita.com/genkitoyama/items/262c5b9c489130eb877d
			}

			fixed4 frag(Varyings input) : SV_Target
			{
				return fixed4(1,1,1,1);
			}

			
			ENDCG
		}
	}
}