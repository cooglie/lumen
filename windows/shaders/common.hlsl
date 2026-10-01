// common.hlsl — gemeinsam genutzte Typen & Vertex-Shader (Vollbild-Dreieck)
// Wird per #include in jeden Pixel-Shader eingebunden.

#ifndef LUMEN_COMMON_HLSL
#define LUMEN_COMMON_HLSL

cbuffer TimeCB : register(b0) {
    float gTime;
};

struct VSOut {
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;
};

// Vollbild-Dreieck: deckt den ganzen Clip-Space mit einem Triangle (SV_VertexID).
VSOut LumenVS(uint id : SV_VertexID) {
    float2 positions[3] = {
        float2(-1.0, -1.0),
        float2( 3.0, -1.0),
        float2(-1.0,  3.0)
    };
    float2 p = positions[id];
    VSOut o;
    o.pos = float4(p, 0.0, 1.0);
    o.uv = p * 0.5 + 0.5;
    o.uv.y = 1.0 - o.uv.y; // Flip für Bildschirmkoordinaten
    return o;
}

#endif
