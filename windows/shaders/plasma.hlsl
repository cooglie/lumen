// plasma.hlsl — klassischer Plasma-Effekt
#include "common.hlsl"

float4 PSMain(VSOut in) : SV_Target {
    float2 uv = in.uv * 8.0;
    float t = gTime * 0.5;
    float v = sin(uv.x + t);
    v += sin((uv.y + t) * 0.6);
    v += sin((uv.x + uv.y + t) * 0.5);
    float2 c = uv + float2(sin(t * 0.4), cos(t * 0.3)) * 2.0;
    v += sin(length(c) + t);
    v *= 0.5;
    float3 col = float3(
        sin(v * 3.1415),
        sin(v * 3.1415 + 2.094),
        sin(v * 3.1415 + 4.188)
    ) * 0.5 + 0.5;
    return float4(col, 1.0);
}
