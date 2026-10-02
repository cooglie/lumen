// cybergrid.hlsl — Synthwave-Grid mit Sonnenuntergang
#include "common.hlsl"

float4 PSMain(VSOut in) : SV_Target {
    float2 uv = in.uv;
    float t = gTime * 0.3;

    float2 sunUV = float2(uv.x, uv.y * 2.0 - 0.3);
    float sunDist = length(float2(sunUV.x - 0.5, sunUV.y - 0.7));
    float sun = smoothstep(0.15, 0.12, sunDist);
    float stripes = step(0.0, sin((sunUV.y - 0.7) * 40.0 + t * 2.0));
    sun *= lerp(0.3, 1.0, stripes);
    float3 sunCol = lerp(float3(1.0, 0.8, 0.2), float3(1.0, 0.3, 0.6), 1.0 - uv.y);

    float3 col = float3(0.02, 0.0, 0.08);
    if (uv.y < 0.5) {
        float gx = uv.x * 2.0 - 1.0;
        float gy = (0.5 - uv.y) * 3.0 + t;
        float persp = gy;
        gx /= persp;
        float lineX = smoothstep(0.02, 0.0, abs(frac(gx * 4.0) - 0.5) - 0.46);
        float lineY = smoothstep(0.015, 0.0, abs(frac(gy * 2.0) - 0.5) - 0.48);
        float gridLines = max(lineX, lineY) * smoothstep(0.5, 0.1, uv.y);
        col += float3(1.0, 0.1, 0.8) * gridLines;
    }
    col += sunCol * sun * 0.8;
    float glow = exp(-abs(uv.y - 0.5) * 15.0) * 0.2;
    col += float3(1.0, 0.4, 0.8) * glow;
    return float4(col, 1.0);
}
