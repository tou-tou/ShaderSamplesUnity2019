Shader "TouTou/WaveShader"
{
	Properties
	{
		_S2("PhaseVelocity^2",Range(0.0,0.5)) = 0.2
		_Atten("Attenuation",Range(0.0,1.0)) = 0.999
		_DeltaUV("Delta UV",Float)=3
	}
	SubShader
	{
		Cull Off
		Zwrite Off
		ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex CustomRenderTextureVertexShader
			#pragma fragment frag
			
			#include "UnityCustomRenderTexture.cginc"

			half _S2;
			half _Atten;
			float _DeltaUV;
			sampler2D _MainTex;

			float4 frag(v2f_customrendertexture  i) : SV_Target
            {
                float2 uv = i.globalTexcoord;

                // 1pxあたりの単位を計算する
                float du = 1.0 / _CustomRenderTextureWidth;
                float dv = 1.0 / _CustomRenderTextureHeight;
                float3 duv = float3(du, dv, 0) * _DeltaUV;

                // 現在の位置のテクセルをフェッチ
                float4 c = tex2D(_SelfTexture2D, uv);

                // 波動方程式
            	// A(t+1)+A(t-1)-2A(t)=A(x+1)+A(x-1)+A(y+1)+A(y-1)-4A(x,y)
                float k = (2.0 * c.r) - c.g;
                float p = (k + _S2 * (
                    tex2D(_SelfTexture2D, uv - float2(duv.x,0)).r +
                    tex2D(_SelfTexture2D, uv + float2(duv.x,0)).r +
                    tex2D(_SelfTexture2D, uv - float2(0,duv.y)).r +
                    tex2D(_SelfTexture2D, uv + float2(0,duv.y)).r - 4.0 * c.r
                )) * _Atten;

                // 現在の状態をテクスチャのR成分に、ひとつ前の（過去の）状態をG成分に書き込む。
                return float4(p, c.r, 0, 0);
            }
			
			ENDCG
		}
	}
}