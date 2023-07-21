Shader "Slime/Sryme"
{
    Properties 
    {
        //[IntRange] _SphereCount("SphereCount",Range(0,128)) = 32
        //[IntRange] _Freq("frequency",Range(0,128)) = 10
        _RadRate("radius Rate",Range(0,2)) = 0.3
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
        }
        Cull Front
        
        Pass
        {
            ZWrite On // 深度を書き込む
            Blend SrcAlpha OneMinusSrcAlpha // 透過できるようにする
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            

            #include "UnityCG.cginc"
            #define  MAX_SPHERE_COUNT 256 //最大の球の個数
            float4 _Spheres[MAX_SPHERE_COUNT];//球の座標・半径を格納した配列
            int _SphereCount;
            int _Freq;
            float _RadRate;

            // 入力データ用の構造体
            struct appdata
            {
                float4 vertex : POSITION; // 頂点座標
                float2 uv : TEXCOORD0;
            };

            // vertで計算してfragに渡す用の構造体
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 pos : TEXCOORD1;
                float4 vertex : SV_POSITION; // 頂点座標
            };

            // 出力データ用の構造体
            struct output
            {
                float4 col: SV_Target; // ピクセル色
                float depth : SV_Depth; // 深度
            };
            

            // 入力 -> v2f
            v2f vert(const appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.pos = v.vertex.xyz;//メッシュのローカル座標を代入
                o.uv = v.uv;
                return o;
            }
            

            //球の距離関数
            float sphereDistanceFunction(float4 sphere, float3 pos)
            {
                return length(sphere.xyz - pos) - sphere.w;
            }

            //深度計算
            inline float getDepth(float3 pos)
            {
                //const float4 vpPos = mul(UNITY_MATRIX_VP, float4(pos,1.0));
                float4 vpPos = UnityObjectToClipPos(float4(pos, 1.0));
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

            float smoothMin(float x1 , float x2, float k)
            {
                return -log(exp(-k * x1) + exp(-k * x2)) / k;
            }
            
            //いずれかの球との最短距離を返す
            float getDistance(float3 pos)
            {
                float dist = 100000;
                for(int i=0;i< _SphereCount; i++)
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

            fixed3 _Colors[MAX_SPHERE_COUNT];

            fixed3 getColor(const float3 pos)
            {
                fixed3 color = fixed3(0,0,0);
                float weight = 0.01;
                for (int i = 0; i < _SphereCount ; ++i)
                {
                    const float distinctness = 0.7 ;
                    const float4 sphere = _Spheres[i];
                    const float x = clamp((length(sphere.xyz - pos) - sphere.w) * distinctness, 0, 1);
                    const float t = 1.0 - x * x * (3.0 - 2.0 * x);
                    color += t * _Colors[i];
                    weight += t;
                }
                color /= weight;
                return float4(color, 1);
            }
            

            float3 getNormal(const float3 pos)
            {
                float d = 0.0001;
                return normalize(float3(
                   getDistance(pos + float3(d, 0.0, 0.0)) - getDistance(pos + float3(-d, 0.0, 0.0)),
                   getDistance(pos + float3(0.0, d, 0.0)) - getDistance(pos + float3(0.0, -d, 0.0)),
                   getDistance(pos + float3(0.0, 0.0, d)) - getDistance(pos + float3(0.0, 0.0, -d))
                ));
            }

            float randRange(float2 seed, float r)
            {
                return 2*r*(rand(seed) - 0.5);//-r ~ r
            }

            // v2f -> 出力
            output frag( v2f i)
            {
                output o;
                float3 rayOrigin = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos,1)).xyz;
                float3 pos = i.pos.xyz;//レイの座標
                const float3 rayDir = normalize(pos - rayOrigin);//レイの進行方向
                _SphereCount = 32;

                // 球の座標と半径をランダムに設定
                [unroll]
                for(int x=0; x < _SphereCount; x++)
                {
                    float T  = 2;
                    float r = sin(_Time * 20 + randRange(x,T));
                    float centerX = r*cos(randRange(x,UNITY_PI));
                    float centerY = r*cos(randRange(x+1,UNITY_PI)) + 0.5;
                    float centerZ = r*cos(randRange(x+2,UNITY_PI));
                    
                    float3 center = float3(centerX,centerY,centerZ) * 4 - 2;
                    float radius = rand(x+3) * _RadRate;
                    _Spheres[x] = float4(center ,radius);
                    _Colors[x] = fixed3(rand(x),rand(x+1),rand(x+2));
                }

                float dist = 0;
                float totalDist = 0;
                for(int i=0 ; i < 30 ; i++)
                {
                    pos = rayOrigin + rayDir * totalDist;
                    //posといずれかの球との最短距離
                    dist = getDistance(pos);
                    //レイの方向に行進
                    totalDist += dist;
                }

                //距離が0.001以下になったら、色と深度を書き込んで処理終了
                [unroll]
                if(dist < 0.01){
                    fixed3 norm = getNormal(pos);//法線
                    fixed3 baseColor = getColor(pos); //ベースとなる色
                    const float rimPower = 2;
                    const float rimRate =  pow(1 - abs(dot(norm, rayDir)), rimPower); // 輪郭らしさの指標
                    const fixed3 rimColor = fixed3(1.5, 1.5, 1.5); // 輪郭の色
                    
                    fixed3 color = clamp(lerp(baseColor, rimColor, rimRate), 0, 1); // 色
                    float alpha = clamp(lerp(0.2, 4, rimRate), 0, 1); // 不透明度
                    o.col = fixed4(color,1);//塗りつぶし
                    o.depth = getDepth(pos);//深度書き込み
                }
                else {
                    // 衝突判定がなかったら透明にする
                    o.col =  fixed4(0.5,0.5,0.5,1);
                    o.depth = 0;
                    // discard;
                }
                return o;
            }
            ENDCG
        }
    }
}