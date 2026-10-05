// voronoi.hlsl — Kristalline Voronoi-Zellen mit Glanz
#include "common.hlsl"

float2 hash2(float2 p) {
    return frac(sin(float2(
        dot(p, float2(127.1, 311.7)),
        dot(p, float2(269.5, 183.3))
    )) * 43758.5453);
}

float4 PSMain(VSOut in) : SV_Target {
    float2 uv = in.uv * 6.0;
    float t = gTime * 0.2;

    float minDist = 1.0;
    float secondDist = 1.0;
    float2 closest = float2(0.0, 0.0);

    float2 i = floor(uv);
    float2 f = frac(uv);
    [unroll]
    for (int y = -1; y <= 1; y++) {
        [unroll]
        for (int x = -1; x <= 1; x++) {
            float2 neighbor = float2((float)x, (float)y);
            float2 point = hash2(i + neighbor);
            point = 0.5 + 0.5 * sin(t + 6.2831 * point);
            float2 diff = neighbor + point - f;
            float d = length(diff);
            if (d < minDist) {
                secondDist = minDist;
                minDist = d;
                closest = i + neighbor;
            } else if (d < secondDist) {
                secondDist = d;
            }
        }
    }

    float edge = smoothstep(0.0, 0.04, secondDist - minDist);
    float3 cellColor = float3(hash2(closest), 1.0 - hash2(closest).x);
    cellColor = pow(cellColor, float3(2.2, 2.2, 2.2));
    float glow = smoothstep(0.5, 0.0, minDist) * 0.4;
    float3 col = cellColor * (0.3 + glow);
    col = lerp(float3(0.0, 0.0, 0.0), col, edge);
    return float4(col, 1.0);
}
