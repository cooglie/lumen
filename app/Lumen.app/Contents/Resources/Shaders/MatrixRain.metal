//
//  MatrixRain.metal — Digitaler Matrix-Regen
//
#include <metal_stdlib>
using namespace metal;

float hash_m(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

// Pseudo-Zeichen als Helligkeitsmuster.
float char(float2 uv, float seed) {
    float c = 0.0;
    float2 g = fract(uv * 8.0) - 0.5;
    // Zufällige Striche pro "Zeichen".
    float r = hash_m(floor(uv * 8.0) + seed);
    if (r > 0.3) c += smoothstep(0.4, 0.3, abs(g.x));
    if (r > 0.6) c += smoothstep(0.4, 0.3, abs(g.y));
    if (r > 0.8) c += smoothstep(0.3, 0.2, length(g));
    return c * step(0.1, r);
}

fragment float4 matrixrain_fragment(VertexOut in [[stage_in]],
                                    constant float &time [[buffer(0)]]) {
    float2 uv = in.uv;
    uv.x *= 1.5;

    // Spalten.
    float colSpeed = 2.0 + hash_m(float2(floor(uv.x * 30.0), 0.0)) * 3.0;
    float colOffset = hash_m(float2(floor(uv.x * 30.0), 1.0)) * 10.0;

    // Scrollende Y-Position.
    float y = uv.y * 12.0 - time * colSpeed + colOffset;
    float2 cellUV = float2(uv.x * 30.0, y);

    float cell = floor(y);
    float r = hash_m(float2(cell, floor(uv.x * 30.0)));

    // Zeichen-Helligkeit.
    float brightness = char(cellUV, cell) * (0.3 + r * 0.7);

    // Kopf der Säule = heller (weiß), Rest grün.
    float headDist = fract(y);
    float isHead = smoothstep(0.9, 1.0, headDist);
    float trail = smoothstep(0.0, 0.7, headDist);

    float3 green = float3(0.0, 1.0, 0.3);
    float3 white = float3(0.7, 1.0, 0.7);
    float3 col = green * brightness * trail;
    col += white * isHead * brightness * 1.5;

    // Dunkler Hintergrund.
    col = max(col, float3(0.0, 0.02, 0.0));

    return float4(col, 1.0);
}
