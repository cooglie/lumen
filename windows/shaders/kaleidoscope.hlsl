// kaleidoscope.hlsl — Symmetrisches Mandala mit Farbzyklus
#include "common.hlsl"

float hash_k(float2 p) {
    return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}
float noise_k(float2 p) {
    float2 i = floor(p), f = frac(p);
    f = f * f * (3.0 - 2.0 * f);
    return lerp(lerp(hash_k(i), hash_k(i + float2(1, 0)), f.x),
               lerp(hash_k(i + float2(0, 1)), hash_k(i + float2(1, 1)), f.x), f.y);
}

float4 PSMain(VSOut in) : SV_Target {
    float2 uv = in.uv - 0.5;
    uv.x *= 1.5;

    float r = length(uv);
    float a = atan2(uv.y, uv.x);

    float segments = 8.0;
    float segAngle = 6.2831 / segments;
    a = abs(fmod(a, segAngle) - segAngle * 0.5);
    a += gTime * 0.3;

    float2 p = float2(cos(a), sin(a)) * r * 4.0;

    float v = 0.0;
    v += noise_k(p + gTime * 0.5) * 0.5;
    v += noise_k(p * 2.0 - gTime * 0.3) * 0.25;
    v += noise_k(p * 4.0 + gTime * 0.7) * 0.125;

    float hue = frac(v + gTime * 0.1);
    float3 col;
    col.r = sin(hue * 6.28 + 0.0) * 0.5 + 0.5;
    col.g = sin(hue * 6.28 + 2.09) * 0.5 + 0.5;
    col.b = sin(hue * 6.28 + 4.18) * 0.5 + 0.5;

    float rings = sin(r * 30.0 - gTime * 2.0) * 0.3 + 0.7;
    col *= rings;
    col += float3(1.0, 0.9, 0.8) * exp(-r * 5.0) * 0.3;
    col *= 1.0 - r * 0.5;

    return float4(col, 1.0);
}
