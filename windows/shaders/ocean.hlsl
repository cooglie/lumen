// ocean.hlsl — Animierte Ozeanwellen
#include "common.hlsl"

float hash_o(float2 p) {
    return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}
float noise_o(float2 p) {
    float2 i = floor(p), f = frac(p);
    f = f * f * (3.0 - 2.0 * f);
    return lerp(lerp(hash_o(i), hash_o(i + float2(1, 0)), f.x),
               lerp(hash_o(i + float2(0, 1)), hash_o(i + float2(1, 1)), f.x), f.y);
}

float4 PSMain(VSOut in) : SV_Target {
    float2 uv = in.uv;
    float t = gTime * 0.4;
    float h = 0.0;
    h += noise_o(float2(uv.x * 6.0 + t, uv.y * 3.0))         * 0.5;
    h += noise_o(float2(uv.x * 12.0 - t * 0.7, uv.y * 6.0))  * 0.25;
    h += noise_o(float2(uv.x * 24.0 + t * 1.3, uv.y * 12.0)) * 0.12;
    h *= smoothstep(0.0, 0.4, uv.y) + 0.3;

    float3 deep    = float3(0.02, 0.08, 0.2);
    float3 shallow = float3(0.1, 0.4, 0.6);
    float3 crest   = float3(0.7, 0.9, 1.0);
    float3 col = lerp(deep, shallow, h);
    col = lerp(col, crest, smoothstep(0.6, 0.9, h));

    float sparkle = pow(noise_o(float2(uv.x * 80.0, uv.y * 80.0 + t * 5.0)), 20.0);
    col += float3(1.0, 1.0, 1.0) * sparkle * smoothstep(0.3, 0.7, uv.y);
    col = lerp(col, float3(0.6, 0.75, 0.85), smoothstep(0.7, 0.95, uv.y) * 0.5);
    return float4(col, 1.0);
}
