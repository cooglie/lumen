//
//  CyberGrid.metal — Synthwave-Grid mit Sonnenuntergang
//
#include <metal_stdlib>
using namespace metal;

fragment float4 cybergrid_fragment(VertexOut in [[stage_in]],
                                   constant float &time [[buffer(0)]]) {
    float2 uv = in.uv;
    float t = time * 0.3;

    // --- Sonne ---
    float2 sunUV = float2(uv.x, uv.y * 2.0 - 0.3);
    float sunDist = length(float2(sunUV.x - 0.5, sunUV.y - 0.7));
    float sun = smoothstep(0.15, 0.12, sunDist);
    // Sonnenstreifen.
    float stripes = step(0.0, sin((sunUV.y - 0.7) * 40.0 + t * 2.0));
    sun *= mix(0.3, 1.0, stripes);
    float3 sunCol = mix(float3(1.0, 0.8, 0.2), float3(1.0, 0.3, 0.6), 1.0 - uv.y);

    // --- Grid (Boden) ---
    float3 col = float3(0.02, 0.0, 0.08); // Dunkellila Himmel
    if (uv.y < 0.5) {
        float2 grid;
        grid.x = uv.x * 2.0 - 1.0;
        grid.y = (0.5 - uv.y) * 3.0 + t; // Scrollt auf Betrachter zu

        // Perspektive: X streckt sich zum Horizont.
        float persp = grid.y;
        grid.x /= persp;

        float lineX = smoothstep(0.02, 0.0, abs(fract(grid.x * 4.0) - 0.5) - 0.46);
        float lineY = smoothstep(0.015, 0.0, abs(fract(grid.y * 2.0) - 0.5) - 0.48);
        float gridLines = max(lineX, lineY) * smoothstep(0.5, 0.1, uv.y);

        col += float3(1.0, 0.1, 0.8) * gridLines; // Neon-Magenta Grid
    }

    // Sonne drüber.
    col += sunCol * sun * 0.8;

    // Horizont-Glühen.
    float glow = exp(-abs(uv.y - 0.5) * 15.0) * 0.2;
    col += float3(1.0, 0.4, 0.8) * glow;

    return float4(col, 1.0);
}
