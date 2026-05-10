Shader "Custom/TerrainWithVertexPaint"
{
    Properties
    {
        _Uv_Scales("Uv Scales", Float) = 1
        [NoScaleOffset]_A_Abledo("A - Abledo", 2D) = "white" {}
        [NoScaleOffset]_B_Albedo("B - Albedo", 2D) = "white" {}
        [Normal][NoScaleOffset]_A_Normal("A - Normal", 2D) = "bump" {}
        [Normal][NoScaleOffset]_B_Normal("B - Normal", 2D) = "bump" {}
        [NoScaleOffset]_A_MAOHS("A - MAOHS", 2D) = "white" {}
        [NoScaleOffset]_B_MAOHS("B - MAOHS", 2D) = "white" {}
        _NoiseScale("NoiseScale", Float) = 10
        _Blend_Distance("Blend Distance", Float) = 0.1
        _Snow_Metallic("Snow Metallic", Float) = 0
        _Snow_Smoothness("Snow Smoothness", Float) = 0.02
        _Snow_AO("Snow AO", Float) = 0
        _Vertical_Displacement("Vertical Displacement", Float) = 2
    }
    
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard vertex:vert fullforwardshadows addshadow
        #pragma target 3.0

        sampler2D _A_Abledo;
        sampler2D _B_Albedo;
        sampler2D _A_Normal;
        sampler2D _B_Normal;
        sampler2D _A_MAOHS;
        sampler2D _B_MAOHS;

        float _Uv_Scales;
        float _NoiseScale;
        float _Blend_Distance;
        float _Snow_Metallic;
        float _Snow_Smoothness;
        float _Snow_AO;
        float _Vertical_Displacement;

        struct Input
        {
            float2 uv_A_Abledo;
            float4 color : COLOR;
        };
        
        float2 GradientNoiseDir(float2 p)
        {
            p = p % 289;
            float x = (34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        float GradientNoise(float2 uv, float scale)
        {
            float2 p = uv * scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(GradientNoiseDir(ip), fp);
            float d01 = dot(GradientNoiseDir(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(GradientNoiseDir(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(GradientNoiseDir(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            return lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }
        
        void vert (inout appdata_full v)
        {
            float displacement = v.color.b * _Vertical_Displacement;
            v.vertex.xyz += float3(0, 1, 0) * displacement;
        }

 
        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            float2 unscaledUV = IN.uv_A_Abledo;
            float2 scaledUV = unscaledUV * _Uv_Scales;
            
            float noiseVal = GradientNoise(unscaledUV, _NoiseScale);
            
            float4 oneMinusColor = 1.0 - IN.color;
            float D = _Blend_Distance;
            
            float4 remapped = -D + oneMinusColor * (1.0 + 2.0 * D);
            
            float4 edge1 = remapped - D;
            float4 edge2 = remapped + D;
            
            float4 smoothVal = smoothstep(edge1, edge2, float4(noiseVal, noiseVal, noiseVal, noiseVal));
            
            float maskR = smoothVal.r;
            float maskG = smoothVal.g;
            
            float4 albedoA = tex2D(_A_Abledo, scaledUV);
            float4 albedoB = tex2D(_B_Albedo, scaledUV);
            float3 normalA = UnpackNormal(tex2D(_A_Normal, scaledUV));
            float3 normalB = UnpackNormal(tex2D(_B_Normal, scaledUV));
            float4 maohsA = tex2D(_A_MAOHS, scaledUV);
            float4 maohsB = tex2D(_B_MAOHS, scaledUV);
            
            float4 blendCol = lerp(albedoA, albedoB, maskR);
            float4 finalCol = lerp(blendCol, float4(1.0, 1.0, 1.0, 1.0), maskG);
            o.Albedo = finalCol.rgb;
            
            o.Normal = lerp(normalA, normalB, saturate(maskR));
            
            float blendMet = lerp(maohsA.r, maohsB.r, maskR);
            o.Metallic = lerp(blendMet, _Snow_Metallic, maskG);
            
            float blendSmooth = lerp(maohsA.a, maohsB.a, maskR);
            o.Smoothness = lerp(blendSmooth, _Snow_Smoothness, maskG);
            
            float blendAO = lerp(maohsA.g, maohsB.g, maskR);
            o.Occlusion = lerp(blendAO, _Snow_AO, maskG);
        }
        ENDCG
    }
    FallBack "Diffuse"
}