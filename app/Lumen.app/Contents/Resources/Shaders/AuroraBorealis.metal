//
//  AuroraBorealis.metal — prozedurale Polarlicht-Bänder (nur Fragment-Funktion)
//

#include <metal_stdlib>
using namespace metal;

float hash_a(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}
float noise_a(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash_a(i), hash_a(i + float2(1, 0)), f.x),
               mix(hash_a(i + float2(0, 1)), hash_a(i + float2(1, 1)), f.x), f.y);
}

fragment float4 aurora_fragment(VertexOut in [[stage_in]],
                                constant float &time [[buffer(0)]]) {
    float2 uv = in.uv;
    float t = time * 0.15;
    float band = 0.0;
    for (int i = 0; i < 4; i++) {
        float offset = float(i) * 0.25;
        float wave = sin(uv.x * 6.0 + t + offset) * 0.15;
        float d = abs(uv.y - (0.5 + wave + offset * 0.1));
        band += exp(-d * 12.0) * (0.6 - offset * 0.3);
    }
    band += noise_a(uv * 4.0 + t) * 0.1;

    float3 green = float3(0.1, 1.0, 0.4);
    float3 cyan  = float3(0.2, 0.6, 1.0);
    float3 mag   = float3(0.7, 0.2, 0.9);
    float3 col = mix(green, cyan, uv.y);
    col = mix(col, mag, pow(uv.y, 4.0));
    col *= band;
    col += float3(0.02, 0.02, 0.06);
    return float4(col, 1.0);
}
