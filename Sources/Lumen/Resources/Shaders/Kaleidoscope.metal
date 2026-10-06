//
//  Kaleidoscope.metal — Symmetrisches Mandala mit Farbzyklus
//
#include <metal_stdlib>
using namespace metal;

float hash_k(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}
float noise_k(float2 p) {
    float2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash_k(i), hash_k(i + float2(1, 0)), f.x),
               mix(hash_k(i + float2(0, 1)), hash_k(i + float2(1, 1)), f.x), f.y);
}

fragment float4 kaleidoscope_fragment(VertexOut in [[stage_in]],
                                      constant float &time [[buffer(0)]]) {
    float2 uv = in.uv - 0.5;
    uv.x *= 1.5;

    float r = length(uv);
    float a = atan2(uv.y, uv.x);

    // Symmetrie: 8 Segmente.
    float segments = 8.0;
    float segAngle = 6.2831 / segments;
    a = abs(mod(a, segAngle) - segAngle * 0.5);

    // Rotation über Zeit.
    a += time * 0.3;

    float2 p = float2(cos(a), sin(a)) * r * 4.0;

    // Layered Noise für Muster.
    float v = 0.0;
    v += noise_k(p + time * 0.5) * 0.5;
    v += noise_k(p * 2.0 - time * 0.3) * 0.25;
    v += noise_k(p * 4.0 + time * 0.7) * 0.125;

    // Farbpalette (HSV-ähnlich).
    float hue = fract(v + time * 0.1);
    float3 col;
    col.r = sin(hue * 6.28 + 0.0) * 0.5 + 0.5;
    col.g = sin(hue * 6.28 + 2.09) * 0.5 + 0.5;
    col.b = sin(hue * 6.28 + 4.18) * 0.5 + 0.5;

    // Ring-Muster.
    float rings = sin(r * 30.0 - time * 2.0) * 0.3 + 0.7;
    col *= rings;

    // Zentraler Glow.
    col += float3(1.0, 0.9, 0.8) * exp(-r * 5.0) * 0.3;

    // Vignette.
    col *= 1.0 - r * 0.5;

    return float4(col, 1.0);
}
