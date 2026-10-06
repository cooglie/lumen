// matrixrain.hlsl — Digitaler Matrix-Regen
#include "common.hlsl"

float hash_m(float2 p) {
    return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

float char_fn(float2 uv, float seed) {
    float c = 0.0;
    float2 g = frac(uv * 8.0) - 0.5;
    float r = hash_m(floor(uv * 8.0) + seed);
    if (r > 0.3) c += smoothstep(0.4, 0.3, abs(g.x));
    if (r > 0.6) c += smoothstep(0.4, 0.3, abs(g.y));
    if (r > 0.8) c += smoothstep(0.3, 0.2, length(g));
    return c * step(0.1, r);
}

float4 PSMain(VSOut in) : SV_Target {
    float2 uv = in.uv;
    uv.x *= 1.5;

    float colSpeed = 2.0 + hash_m(float2(floor(uv.x * 30.0), 0.0)) * 3.0;
    float colOffset = hash_m(float2(floor(uv.x * 30.0), 1.0)) * 10.0;

    float y = uv.y * 12.0 - gTime * colSpeed + colOffset;
    float2 cellUV = float2(uv.x * 30.0, y);

    float cell = floor(y);
    float r = hash_m(float2(cell, floor(uv.x * 30.0)));

    float brightness = char_fn(cellUV, cell) * (0.3 + r * 0.7);

    float headDist = frac(y);
    float isHead = smoothstep(0.9, 1.0, headDist);
    float trail = smoothstep(0.0, 0.7, headDist);

    float3 green = float3(0.0, 1.0, 0.3);
    float3 white = float3(0.7, 1.0, 0.7);
    float3 col = green * brightness * trail;
    col += white * isHead * brightness * 1.5;
    col = max(col, float3(0.0, 0.02, 0.0));

    return float4(col, 1.0);
}
