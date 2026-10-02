// fireworks.hlsl — Feuerwerk-Partikel-Explosionen
#include "common.hlsl"

float hash_f(float2 p) {
    return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

float4 PSMain(VSOut in) : SV_Target {
    float2 uv = in.uv;
    uv.x *= 1.5;
    float t = gTime;
    float3 col = float3(0.01, 0.01, 0.03);

    [unroll]
    for (int i = 0; i < 5; i++) {
        float fi = (float)i;
        float cycle = 2.5 + fi * 0.4;
        float phase = frac(t / cycle);
        float age = phase;
        float2 center = float2(
            0.2 + hash_f(float2(fi, 1.0)) * 0.6,
            0.3 + hash_f(float2(fi, 2.0)) * 0.4
        );
        float radius = age * 0.25;
        float fade = exp(-age * 3.0);
        float d = length(uv - center);
        float ring = smoothstep(0.005, 0.0, abs(d - radius));
        float angle = atan2(uv.y - center.y, uv.x - center.x);
        float spokes = sin(angle * (6.0 + fi * 2.0)) * 0.5 + 0.5;
        ring *= 0.4 + spokes * 0.6;

        float3 fcol;
        if (i == 0) fcol = float3(1.0, 0.3, 0.3);
        else if (i == 1) fcol = float3(0.3, 1.0, 0.4);
        else if (i == 2) fcol = float3(0.4, 0.6, 1.0);
        else if (i == 3) fcol = float3(1.0, 0.9, 0.2);
        else fcol = float3(1.0, 0.4, 1.0);

        col += fcol * ring * fade;
    }

    float stars = pow(hash_f(uv * 300.0), 40.0);
    col += float3(0.8, 0.9, 1.0) * stars * 0.3;
    return float4(col, 1.0);
}
