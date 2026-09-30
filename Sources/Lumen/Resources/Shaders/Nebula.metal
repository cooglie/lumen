//
//  Nebula.metal
//  Lumen — Aurora Shader Pack
//
//  Ein fließender Farbraum-Nebel. Vollständig im Fragment-Shader berechnet
//  aus Zeit + UV. Platzhalter bis der echte Uniform-Buffer angebunden ist.
//

#include <metal_stdlib>
using namespace metal;

// Fragment-Eingabe: UV-Koordinaten (0..1) über das Vollbild-Quad.
struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

// Hash & Noise — billige prozedurale Bausteine.
float hash(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

float noise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + float2(1.0, 0.0));
    float c = hash(i + float2(0.0, 1.0));
    float d = hash(i + float2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

fragment float4 nebula_fragment(VertexOut in [[stage_in]],
                                constant float &time [[buffer(0)]]) {
    float2 uv = in.uv * 3.0;
    float t = time * 0.1;

    // Schichtweise FBM-Verdrillung.
    float n = 0.0;
    n += noise(uv + float2(t, 0.0))        * 0.5;
    n += noise(uv * 2.0 + float2(0.0, t))  * 0.25;
    n += noise(uv * 4.0 - float2(t, t))    * 0.125;

    // Farbverlauf von tiefem Violett über Magenta zu Türkis.
    float3 c1 = float3(0.05, 0.02, 0.15);
    float3 c2 = float3(0.6, 0.1, 0.5);
    float3 c3 = float3(0.1, 0.7, 0.8);
    float3 col = mix(c1, c2, n);
    col = mix(col, c3, pow(n, 3.0));

    return float4(col, 1.0);
}
