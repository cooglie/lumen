//
//  Nebula.metal — fließender Farbraum-Nebel (nur Fragment-Funktion)
//

#include <metal_stdlib>
using namespace metal;

float hash_n(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}
float noise_n(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash_n(i);
    float b = hash_n(i + float2(1.0, 0.0));
    float c = hash_n(i + float2(0.0, 1.0));
    float d = hash_n(i + float2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

fragment float4 nebula_fragment(VertexOut in [[stage_in]],
                                constant float &time [[buffer(0)]]) {
    float2 uv = in.uv * 3.0;
    float t = time * 0.1;
    float n = 0.0;
    n += noise_n(uv + float2(t, 0.0))        * 0.5;
    n += noise_n(uv * 2.0 + float2(0.0, t))  * 0.25;
    n += noise_n(uv * 4.0 - float2(t, t))    * 0.125;

    float3 c1 = float3(0.05, 0.02, 0.15);
    float3 c2 = float3(0.6, 0.1, 0.5);
    float3 c3 = float3(0.1, 0.7, 0.8);
    float3 col = mix(c1, c2, n);
    col = mix(col, c3, pow(n, 3.0));
    return float4(col, 1.0);
}
