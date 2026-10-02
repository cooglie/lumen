// starfield.hlsl — Warp-Speed-Sternenfeld
#include "common.hlsl"

float4 PSMain(VSOut in) : SV_Target {
    float2 uv = in.uv * 2.0 - 1.0;
    uv.x *= 1.5;
    float3 col = float3(0.0, 0.0, 0.0);

    [unroll]
    for (int layer = 0; layer < 3; layer++) {
        float speed = 0.5 + (float)layer * 0.8;
        float2 p = uv;
        float ang = atan2(p.y, p.x);
        float r = length(p);
        float warp = gTime * speed;
        float a = ang + warp * 0.3;
        float star_r = frac(r * 8.0 - warp);
        float star = smoothstep(0.95, 1.0, star_r) * (1.0 - r * 0.5);
        float tw = sin(gTime * 5.0 + r * 20.0 + (float)layer) * 0.5 + 0.5;
        float brightness = star * tw;
        float3 starCol = float3(1.0, 1.0, 1.0);
        if (layer == 0) starCol = float3(0.8, 0.9, 1.0);
        if (layer == 1) starCol = float3(1.0, 1.0, 0.9);
        if (layer == 2) starCol = float3(1.0, 0.7, 0.4);
        col += starCol * brightness * (0.3 + (float)layer * 0.25);
    }
    float glow = exp(-length(uv) * 4.0) * 0.3;
    col += float3(0.3, 0.5, 1.0) * glow;
    col = min(col, 1.0);
    return float4(col, 1.0);
}
