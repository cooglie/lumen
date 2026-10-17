//
//  Sunset.metal — Animierter Sonnenuntergang mit Gradient und Wolken
//
#include <metal_stdlib>
using namespace metal;

float hash_s(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}
float noise_s(float2 p) {
    float2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash_s(i), hash_s(i + float2(1, 0)), f.x),
               mix(hash_s(i + float2(0, 1)), hash_s(i + float2(1, 1)), f.x), f.y);
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

fragment float4 sunset_fragment(VertexOut in [[stage_in]],
                                constant float &time [[buffer(0)]]) {
    float2 uv = in.uv;
    float t = time * 0.15;

    // Sonnenposition wandert leicht.
    float sunY = 0.32 + sin(t * 0.5) * 0.03;
    float2 sunPos = float2(0.5, sunY);
    float sunDist = length(uv - sunPos);

    // Himmel-Gradient (oben dunkelviolett → unten warm-orange).
    float3 skyTop    = float3(0.08, 0.05, 0.25);   // dunkles Violett
    float3 skyMid    = float3(0.6, 0.2, 0.35);     // Pink/Magenta
    float3 skyHorz   = float3(1.0, 0.55, 0.2);     // Orange
    float3 skyBottom = float3(1.0, 0.85, 0.5);     // Hellgelb am Horizont

    float3 col;
    float h = uv.y;
    if (h < sunY) {
        col = mix(skyHorz, skyBottom, smoothstep(sunY, 0.0, h));
    } else {
        col = mix(skyHorz, skyMid, smoothstep(sunY, sunY + 0.2, h));
        col = mix(col, skyTop, smoothstep(sunY + 0.15, 0.95, h));
    }

    // Sonne: leuchtende Scheibe + Glow.
    float sun = smoothstep(0.05, 0.03, sunDist);
    float glow = smoothstep(0.4, 0.03, sunDist) * 0.6;
    col += float3(1.0, 0.9, 0.6) * sun;
    col += float3(1.0, 0.6, 0.3) * glow;

    // Wolken (fbm-basiert, langsam driftend).
    float2 cloudUV = float2(uv.x * 3.0 + t, uv.y * 2.0);
    float clouds = fbm_s(cloudUV);
    clouds = smoothstep(0.45, 0.75, clouds);

    // Wolken nur im oberen Bereich, am Horizont dichter.
    float cloudMask = smoothstep(0.25, 0.6, uv.y) * (1.0 - smoothstep(0.85, 1.0, uv.y));
    float3 cloudCol = mix(float3(0.8, 0.4, 0.5), float3(1.0, 0.75, 0.55), uv.y);
    col = mix(col, cloudCol, clouds * cloudMask * 0.85);

    // Untere Wolken am Horizont (silhouettenartig, dunkler).
    float2 lowCloudUV = float2(uv.x * 4.0 - t * 0.7, uv.y * 6.0);
    float lowClouds = fbm_s(lowCloudUV);
    lowClouds = smoothstep(0.5, 0.7, lowClouds);
    float lowMask = smoothstep(0.3, 0.15, uv.y);
    col = mix(col, float3(0.15, 0.08, 0.12), lowClouds * lowMask * 0.7);

    return float4(col, 1.0);
}
