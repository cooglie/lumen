// rainripples.hlsl — Regentropfen-Ringe auf dunklem Wasser
#include "common.hlsl"

float hash_r(float2 p) {
    return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

float4 PSMain(VSOut in) : SV_Target {
    float2 uv = in.uv * 8.0;
    float t = gTime;
    float3 col = float3(0.01, 0.02, 0.05);

    [unroll]
    for (int i = 0; i < 6; i++) {
        float fi = (float)i;
        float2 center = float2(
            hash_r(float2(fi, 10.0)),
            hash_r(float2(fi, 20.0))
        ) * 8.0;

        float cycle = 1.5 + fi * 0.3;
        float phase = frac(t / cycle + fi * 0.17);
        float radius = phase * 1.5;
        float fade = (1.0 - phase) * (1.0 - phase);

        float d = length(uv - center);
        float ring = smoothstep(0.08, 0.0, abs(d - radius)) * fade;
        float ring2 = smoothstep(0.05, 0.0, abs(d - radius * 0.85)) * fade * 0.5;
        ring += ring2;
        col += float3(0.3, 0.5, 0.8) * ring * 0.6;
    }

    float n = hash_r(floor(uv * 4.0 + t * 2.0)) * 0.03;
    col += float3(n, n, n);
    float vig = 1.0 - length(in.uv - 0.5) * 0.6;
    col *= vig;
    return float4(col, 1.0);
}
