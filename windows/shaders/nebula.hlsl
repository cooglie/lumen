// nebula.hlsl — fließender Farbraum-Nebel
#include "common.hlsl"

float hash_n(float2 p) {
    return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}
float noise_n(float2 p) {
    float2 i = floor(p);
    float2 f = frac(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash_n(i);
    float b = hash_n(i + float2(1.0, 0.0));
    float c = hash_n(i + float2(0.0, 1.0));
    float d = hash_n(i + float2(1.0, 1.0));
    return lerp(lerp(a, b, f.x), lerp(c, d, f.x), f.y);
}

float4 PSMain(VSOut in) : SV_Target {
    float2 uv = in.uv * 3.0;
    float t = gTime * 0.1;
    float n = 0.0;
    n += noise_n(uv + float2(t, 0.0))        * 0.5;
    n += noise_n(uv * 2.0 + float2(0.0, t))  * 0.25;
    n += noise_n(uv * 4.0 - float2(t, t))    * 0.125;

    float3 c1 = float3(0.05, 0.02, 0.15);
    float3 c2 = float3(0.6, 0.1, 0.5);
    float3 c3 = float3(0.1, 0.7, 0.8);
    float3 col = lerp(c1, c2, n);
    col = lerp(col, c3, pow(n, 3.0));
    return float4(col, 1.0);
}
