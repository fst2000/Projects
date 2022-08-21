Shader "Unlit/SeaShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SecondTex ("Second texture", 2D) = "white" {}
        _WaveSpeed("Wave speed", float) = 0.1
        _NoiseTexture("Noise texture", 2D) = "white" {}
        _WaveHeight("Wave height", float) = 1
        _WaveTiling("Wave tiling", float) = 2
        _WaveLength("Wave length", float) = 1
        _MixSpeed("Mix speed", float) = 1
        _NoiseTiling("Noise tiling", float) = 1



    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
// Upgrade NOTE: excluded shader from DX11; has structs without semantics (struct v2f members waveHeight)
#pragma exclude_renderers d3d11
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _SecondTex;
            float4 _MainTex_ST;
            float _WaveSpeed;
            sampler2D _NoiseTexture;
            float _WaveHeight;
            float _WaveTiling;
            float _WaveLength;
            float _MixSpeed;
            float _NoiseTiling;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                
                float3 worldPosition = mul(unity_ObjectToWorld, v.vertex);
                float2 direction = normalize(-worldPosition.xz);
                float waveHeight = sin(length(worldPosition.xz) / _WaveLength * _Time.w * _WaveSpeed);
                o.vertex.y += waveHeight * _WaveHeight;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }
            fixed4 colMix (fixed4 a, fixed4 b, fixed4 mix) 
            {
	            fixed4 r = (mix * a) + ((1 - mix) *b);
	            return r;
            }
            fixed4 colMix (fixed4 a, fixed4 b, float mix) 
            {
	            fixed4 r = (mix * a) + ((1 - mix) *b);
	            return r;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 noiseDirection = normalize(float2(0.5*_NoiseTiling,0.5*_NoiseTiling) - i.uv);

                fixed4 col1 = tex2D(_MainTex, i.uv - noiseDirection * _Time.w * _WaveSpeed);
                fixed4 col2 = tex2D(_MainTex, i.uv + noiseDirection * _Time.w * _WaveSpeed);
                fixed4 col3 = tex2D(_SecondTex, i.uv + noiseDirection * _Time.w * _WaveSpeed);
                fixed4 fluidMix = tex2D(_NoiseTexture, i.uv * _NoiseTiling + _Time.w * _MixSpeed);
                float heightMix = 1;
                fixed4 col = colMix(col1,col2, fluidMix);
                col = colMix(col,col3, heightMix);


                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }

            
            ENDCG
        }
    }
}
