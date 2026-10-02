//
//  Ocean.metal — Animierte Ozeanwellen mit Reflexionen
//
#include <metal_stdlib>
using namespace metal;

float hash_o(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}
float noise_o(float2 p) {
    float2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash_o(i), hash_o(i + float2(1, 0)), f.x),
               mix(hash_o(i + float2(0, 1)), hash_o(i + float2(1, 1)), f.x), f.y);
}

fragment float4 ocean_fragment(VertexOut in [[stage_in]],
                               constant float &time [[buffer(0)]]) {
    float2 uv = in.uv;
    float t = time * 0.4;

    // Mehrere Wellenschichten überlagern.
    float h = 0.0;
    h += noise_o(float2(uv.x * 6.0 + t, uv.y * 3.0))         * 0.5;
    h += noise_o(float2(uv.x * 12.0 - t * 0.7, uv.y * 6.0))  * 0.25;
    h += noise_o(float2(uv.x * 24.0 + t * 1.3, uv.y * 12.0)) * 0.12;

    // Perspektivische Streckung: weiter weg = flacher.
    h *= smoothstep(0.0, 0.4, uv.y) + 0.3;

    // Wasserfarben.
    float3 deep    = float3(0.02, 0.08, 0.2);
    float3 shallow = float3(0.1, 0.4, 0.6);
    float3 crest   = float3(0.7, 0.9, 1.0);
    float3 col = mix(deep, shallow, h);
    col = mix(col, crest, smoothstep(0.6, 0.9, h));

    // Glitzernde Reflexionen.
    float sparkle = pow(noise_o(float2(uv.x * 80.0, uv.y * 80.0 + t * 5.0)), 20.0);
    col += float3(1.0) * sparkle * smoothstep(0.3, 0.7, uv.y);

    // Horizont-Dunst.
    col = mix(col, float3(0.6, 0.75, 0.85), smoothstep(0.7, 0.95, uv.y) * 0.5);

    return float4(col, 1.0);
}
