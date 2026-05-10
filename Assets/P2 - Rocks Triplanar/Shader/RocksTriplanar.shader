Shader "Custom/RocksTriplanar"
{
    Properties
    {
        [Header(Textures)]
        _MainTex ("Rock Albedo (RGB)", 2D) = "white" {}
        [Normal] _BumpMap ("Rock Normal", 2D) = "bump" {}
        
        [Header(Triplanar Settings)]
        _TextureScale ("Texture Scale", Float) = 1.0
        _BlendSharpness ("Blend Sharpness", Range(1, 20)) = 5.0

        [Header(Coordinate Space)]
        [Toggle(COORDINATES_LOCAL)] _LocalCoords ("Use Local Coordinates", Float) = 0
    }
    
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        #pragma surface surf Standard vertex:vert fullforwardshadows
        
        #pragma multi_compile _ COORDINATES_LOCAL

        #pragma target 3.0

        sampler2D _MainTex;
        sampler2D _BumpMap;
        float _TextureScale;
        float _BlendSharpness;
        
        struct Input
        {
            float3 worldPos;
            float3 localPos;
            float3 worldNormal;
            INTERNAL_DATA
        };

        void vert (inout appdata_full v, out Input o)
        {
            UNITY_INITIALIZE_OUTPUT(Input, o);
            o.localPos = v.vertex.xyz; 
        }
        
        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            float3 projectionCoords;
            #if COORDINATES_LOCAL
                projectionCoords = IN.localPos;
            #else
                projectionCoords = IN.worldPos;
            #endif
            projectionCoords *= _TextureScale;
            
            float3 blendNormal = abs(WorldNormalVector(IN, float3(0,0,1)));
            float3 blendWeights = pow(blendNormal, _BlendSharpness);
            blendWeights = blendWeights / (blendWeights.x + blendWeights.y + blendWeights.z);
            
            float2 uvX = projectionCoords.zy; 
            float2 uvY = projectionCoords.xz; 
            float2 uvZ = projectionCoords.xy; 
            
            float4 colX = tex2D(_MainTex, uvX);
            float4 colY = tex2D(_MainTex, uvY);
            float4 colZ = tex2D(_MainTex, uvZ);
            
            float3 normX = UnpackNormal(tex2D(_BumpMap, uvX));
            float3 normY = UnpackNormal(tex2D(_BumpMap, uvY));
            float3 normZ = UnpackNormal(tex2D(_BumpMap, uvZ));
            
            float4 finalColor = colX * blendWeights.x + colY * blendWeights.y + colZ * blendWeights.z;
            float3 finalNormal = normX * blendWeights.x + normY * blendWeights.y + normZ * blendWeights.z;

            o.Albedo = finalColor.rgb;
            o.Normal = normalize(finalNormal);
            o.Alpha = 1.0;
        }
        ENDCG
    }
    FallBack "Diffuse"
}