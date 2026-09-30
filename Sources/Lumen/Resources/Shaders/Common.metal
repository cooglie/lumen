//
//  Common.metal
//  Lumen — gemeinsamer Vertex-Shader + Uniforms (wird vor jedem Fragment-Shader geprependet)
//

#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

// Vollbild-Dreieck (deckt ganzen Clip-Space mit einem Triangle).
vertex VertexOut lumen_vertex(uint vid [[vertex_id]]) {
    float2 positions[3] = {
        float2(-1, -1),
        float2( 3, -1),
        float2(-1,  3)
    };
    float2 p = positions[vid];
    VertexOut o;
    o.position = float4(p, 0, 1);
    o.uv = p * 0.5 + 0.5;
    o.uv.y = 1.0 - o.uv.y; // Flip für Bildschirmkoordinaten
    return o;
}
