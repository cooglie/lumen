// sunset.hlsl — Animierter Sonnenuntergang mit Gradient und Wolken
#include "common.hlsl"

float hash_s(float2 p) {
    return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}
float noise_s(float2 p) {
    float2 i = floor(p), f = frac(p);
    f = f * f * (3.0 - 2.0 * f);
    return lerp(lerp(hash_s(i), hash_s(i + float2(1, 0)), f.x),
               lerp(hash_s(i + float2(0, 1)), hash_s(i + float2(1, 1)), f.x), f.y);
}
float fbm_s(float2 p) {
    float v = 0.0, a = 0.5;
    for (int i = 0; i < 5; i++) {
        v += a * noise_s(p);
        p *= 2.0;
        a *= 0.5;
    }
    return v;
}

float4 PSMain(VSOut in) : SV_Target {
    float2 uv = in.uv;
    float t = gTime * 0.15;

    float sunY = 0.32 + sin(t * 0.5) * 0.03;
    float2 sunPos = float2(0.5, sunY);
    float sunDist = length(uv - sunPos);

    float3 skyTop    = float3(0.08, 0.05, 0.25);
    float3 skyMid    = float3(0.6, 0.2, 0.35);
    float3 skyHorz   = float3(1.0, 0.55, 0.2);
    float3 skyBottom = float3(1.0, 0.85, 0.5);

    float3 col;
    float h = uv.y;
    if (h < sunY) {
        col = lerp(skyHorz, skyBottom, smoothstep(sunY, 0.0, h));
    } else {
        col = lerp(skyHorz, skyMid, smoothstep(sunY, sunY + 0.2, h));
        col = lerp(col, skyTop, smoothstep(sunY + 0.15, 0.95, h));
    }

    float sun = smoothstep(0.05, 0.03, sunDist);
    float glow = smoothstep(0.4, 0.03, sunDist) * 0.6;
    col += float3(1.0, 0.9, 0.6) * sun;
    col += float3(1.0, 0.6, 0.3) * glow;

    float2 cloudUV = float2(uv.x * 3.0 + t, uv.y * 2.0);
    float clouds = fbm_s(cloudUV);
    clouds = smoothstep(0.45, 0.75, clouds);

    float cloudMask = smoothstep(0.25, 0.6, uv.y) * (1.0 - smoothstep(0.85, 1.0, uv.y));
    float3 cloudCol = lerp(float3(0.8, 0.4, 0.5), float3(1.0, 0.75, 0.55), uv.y);
    col = lerp(col, cloudCol, clouds * cloudMask * 0.85);

    float2 lowCloudUV = float2(uv.x * 4.0 - t * 0.7, uv.y * 6.0);
    float lowClouds = fbm_s(lowCloudUV);
    lowClouds = smoothstep(0.5, 0.7, lowClouds);
    float lowMask = smoothstep(0.3, 0.15, uv.y);
    col = lerp(col, float3(0.15, 0.08, 0.12), lowClouds * lowMask * 0.7);

    return float4(col, 1.0);
}
