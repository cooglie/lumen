//
//  Starfield.metal — Warp-Speed-Sternenfeld (Parallaxe)
//
#include <metal_stdlib>
using namespace metal;

fragment float4 starfield_fragment(VertexOut in [[stage_in]],
                                   constant float &time [[buffer(0)]]) {
    float2 uv = in.uv * 2.0 - 1.0;
    uv.x *= 1.5; // Breitbild-Anpassung
    float3 col = float3(0.0);

    // Drei Schichten mit unterschiedlicher Geschwindigkeit.
    for (int layer = 0; layer < 3; layer++) {
        float speed = 0.5 + float(layer) * 0.8;
        float2 p = uv;
        float ang = atan2(p.y, p.x);
        float r = length(p);

        // Sterne ent Spiralarmen verteilen.
        float warp = time * speed;
        float a = ang + warp * 0.3;
        float spiral = sin(a * 3.0 + float(layer)) * 0.1;
        float star_r = fract(r * 8.0 - warp);
        float star = smoothstep(0.95, 1.0, star_r) * (1.0 - r * 0.5);

        // Twinkling.
        float tw = sin(time * 5.0 + r * 20.0 + float(layer)) * 0.5 + 0.5;
        float brightness = star * tw;

        float3 starCol = float3(1.0);
        if (layer == 0) starCol = float3(0.8, 0.9, 1.0); // Blau (fern)
        if (layer == 1) starCol = float3(1.0, 1.0, 0.9); // Weiß (mittel)
        if (layer == 2) starCol = float3(1.0, 0.7, 0.4); // Orange (nah)

        col += starCol * brightness * (0.3 + float(layer) * 0.25);
    }

    // Zentrales Glühen (Warp-Core).
    float glow = exp(-length(uv) * 4.0) * 0.3;
    col += float3(0.3, 0.5, 1.0) * glow;

    col = min(col, 1.0);
    return float4(col, 1.0);
}
