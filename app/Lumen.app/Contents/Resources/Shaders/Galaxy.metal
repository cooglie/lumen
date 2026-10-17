//
//  Galaxy.metal — Spiralgalaxie mit rotierenden Sternen und Kern
//
#include <metal_stdlib>
using namespace metal;

float hash_g(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

fragment float4 galaxy_fragment(VertexOut in [[stage_in]],
                                constant float &time [[buffer(0)]]) {
    float2 uv = in.uv - 0.5;
    uv.x *= 1.7; // Seitenverhältnis ausgleichen
    float t = time * 0.1;

    float r = length(uv);
    float a = atan2(uv.y, uv.x);

    // Spiralarme: Winkelmodulation basierend auf Radius.
    float arms = 2.0;
    float spiral = sin(arms * a + r * 8.0 - t * 3.0);

    // Sternenfeld entlang der Spirale.
    float stars = 0.0;
    float2 grid = floor(uv * 30.0);
    float starRand = hash_g(grid);
    float starDist = length(fract(uv * 30.0) - 0.5);
    float twinkle = 0.5 + 0.5 * sin(t * 5.0 + starRand * 30.0);
    stars = smoothstep(0.04, 0.0, starDist) * twinkle * step(0.92, starRand);

    // Heller Kern (Bulge).
    float core = exp(-r * 12.0);
    float3 coreCol = float3(1.0, 0.95, 0.8) * core * 1.5;

    // Galaktische Scheibe (Staub + Sterne in Spiralform).
    float disk = exp(-r * 2.5) * (0.5 + 0.5 * spiral);
    float3 diskCol = mix(float3(0.3, 0.5, 0.9), float3(0.8, 0.6, 1.0), spiral * 0.5 + 0.5) * disk;

    // Farbverlauf außen → innen: blau (Außenarm) → gelb (Kern).
    float3 armCol = mix(float3(0.15, 0.2, 0.5), float3(1.0, 0.8, 0.5), smoothstep(0.5, 0.0, r));

    // Hintergrundsterne (Tausende kleine, verteilt).
    float2 bgGrid = floor(uv * 80.0);
    float bgStar = hash_g(bgGrid);
    float bgTwinkle = 0.5 + 0.5 * sin(t * 3.0 + bgStar * 50.0);
    float bgDot = step(0.985, bgStar) * bgTwinkle;

    float3 col = float3(0.005, 0.005, 0.02); // dunkler Weltraum-Hintergrund
    col += float3(1.0) * bgDot * 0.7;
    col += armCol * stars * 2.0;
    col += diskCol * 0.4;
    col += coreCol;

    // Leichter vignettenartiger Dunkelrand.
    col *= smoothstep(1.3, 0.3, r);

    return float4(col, 1.0);
}
