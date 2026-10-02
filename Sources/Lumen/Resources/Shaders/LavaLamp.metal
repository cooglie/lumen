//
//  LavaLamp.metal — Metaball-Lavalampen-Blobs
//
#include <metal_stdlib>
using namespace metal;

float2x2 rot(float a) {
    float c = cos(a), s = sin(a);
    return float2x2(c, -s, s, c);
}

fragment float4 lavalamp_fragment(VertexOut in [[stage_in]],
                                  constant float &time [[buffer(0)]]) {
    float2 uv = in.uv;
    uv.x *= 1.5;

    float t = time * 0.3;

    // Vier wandernde Blobs.
    float blobs[4];
    for (int i = 0; i < 4; i++) {
        float fi = float(i);
        float2 p = uv - 0.5;
        p = rot(t * (0.3 + fi * 0.1)) * p;
        p.x += sin(t + fi * 1.5) * 0.3;
        p.y += cos(t * 0.7 + fi * 2.0) * 0.25;
        float r = length(p);
        blobs[i] = 0.06 / (r * r + 0.01);
    }

    float v = blobs[0] + blobs[1] + blobs[2] + blobs[3];
    v = smoothstep(0.8, 2.5, v);

    // Wärme-Farbverlauf: dunkelrot → orange → gelb → weiß.
    float3 c1 = float3(0.3, 0.0, 0.05);
    float3 c2 = float3(0.9, 0.2, 0.0);
    float3 c3 = float3(1.0, 0.7, 0.1);
    float3 c4 = float3(1.0, 1.0, 0.9);
    float3 col = mix(c1, c2, v);
    col = mix(col, c3, smoothstep(0.4, 0.7, v));
    col = mix(col, c4, smoothstep(0.8, 1.0, v));

    col *= 0.9;
    return float4(col, 1.0);
}
