Shader "Slime/Sryme"
{
    Properties {}
    SubShader
    {
        Tags
        {
            "Queue" = "Transparent" // 透過できるようにする
        }

        Pass
        {
            ZWrite On // 深度を書き込む
            Blend SrcAlpha OneMinusSrcAlpha // 透過できるようにする

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            // 入力データ用の構造体
            struct input
            {
                float4 vertex : POSITION; // 頂点座標
                float2 uv : TEXCOORD0;
            };

            // vertで計算してfragに渡す用の構造体
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 posl : TEXCOORD1;
                float4 pos : POSITION1; // ピクセルワールド座標
                float4 vertex : SV_POSITION; // 頂点座標
                
            };

            // 出力データ用の構造体
            struct output
            {
                float4 col: SV_Target; // ピクセル色
                float depth : SV_Depth; // 深度
            };

            // 入力 -> v2f
            v2f vert(const input v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.pos = mul(unity_ObjectToWorld, v.vertex); // ローカル座標をワールド座標に変換
                o.posl = v.vertex.xyz;//メッシュのローカル座標を代入
                o.uv = v.uv;
                return o;
            }

            //球の距離関数
            float4 sphereDistanceFunction(float4 sphere, float3 pos)
            {
                return length(sphere.xyz - pos) - sphere.w;
            }

            //深度計算
            inline float getDepth(float3 pos)
            {
                const float4 vpPos = mul(UNITY_MATRIX_VP, float4(pos,1.0));
                
                float z = vpPos.z / vpPos.w;

                #if defined(SHADER_API_GLCORE) || \
                    defined(SHADER_API_OPENGL) || \
                    defined(SHADER_API_GLES)   || \
                    defined(SHADER_API_GLES3)
                return z * 0.5 + 0.5;
                #else
                return z;
                #endif
                
            }

            #define  MAX_SPHERE_COUNT 256 //最大の球の個数
            float4 _Spheres[MAX_SPHERE_COUNT];//球の座標・半径を格納した配列
            int _SphereCount;//処理する球の個数
            

            float smoothMin(float x1 , float x2, float k)
            {
                return -log(exp(-k * x1) + exp(-k * x2)) / k;
            }

            
            //いずれかの球との最短距離を返す
            float getDistance(float3 pos)
            {
                float dist = 100000;
                for(int i=0;i<_SphereCount; i++)
                {
                    //dist = min(dist, sphereDistanceFunction(_Spheres[i],pos));
                    dist = smoothMin(dist, sphereDistanceFunction(_Spheres[i], pos), 3);
                }
                return dist;
            }

            //ランダムな値を返す(後で削除)
            float rand(float2 seed)
            {
                return frac(sin(dot(seed.xy, float2(12.9898,78.233)))*43758.5453);
            }

            // v2f -> 出力
            output frag(const v2f i)
            {
                output o;
                float3 ro = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos,1)).xyz;
                float3 pos = i.pos.xyz;//レイの座標
                const float3 rayDir = normalize(pos.xyz - _WorldSpaceCameraPos);//レイの進行方向


                // 球の座標と半径をランダムに設定
                _SphereCount = 100;
                for(int x=0; x < _SphereCount; x++)
                {
                    //float3 center = float3(rand(x),rand(x+1),rand(x+2)) * 8  - 4;
                    float centerX = rand(x) + cos(_Time * rand(x) * 10);
                    float centerY = rand(x+1) + sin(_Time *rand(x+1)* 10);
                    float centerZ = rand(x+2) + sin(_Time *rand(x+2)* 10);
                    float3 center = float3(centerX,centerY,centerZ) *8 -4;
                    float radius = rand(x+3) * .5;
                    _Spheres[x] = float4(center ,radius);
                }

                float4 sphere = float4(0,1,0,0.5);//球の座標と半径
                float dist = 0;
                for(int i=0 ; i < 30 ; i++)
                {
                    //posといずれかの球との最短距離
                    dist = getDistance(pos);
                     // posと球との最短距離
                     // float dist = sphereDistanceFunction(sphere, pos);
                    //レイの方向に行進
                    pos +=  dist * rayDir;
                }

                //距離が0.001以下になったら、色と深度を書き込んで処理終了
                if(dist < 0.001)
                {
                    o.col = fixed4(0,1,0,0.5);//塗りつぶし
                    o.depth = getDepth(pos);//深度書き込み
                    return o;
                }
                else
                {
                    // 衝突判定がなかったら透明にする
                o.col = 0;
                o.depth = 0;
                }

                
                return o;
            }
            ENDCG
        }
    }
}