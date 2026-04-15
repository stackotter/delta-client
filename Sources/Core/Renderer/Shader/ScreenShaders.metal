#include <metal_stdlib>
using namespace metal;

constant float2 quadVertices[] = {
  float2(-1.0,  1.0),
  float2(-1.0, -1.0),
  float2( 1.0, -1.0),
  float2(-1.0,  1.0),
  float2( 1.0,  1.0),
  float2( 1.0, -1.0)
};

struct QuadVertex {
  float4 position [[position]];
  float2 uv;
};

vertex QuadVertex screenVertexFunction(uint id [[vertex_id]]) {
  auto quadVertex = quadVertices[id];
  return {
    .position = float4(quadVertex, 1.0, 1.0),
    .uv =  quadVertex * float2(0.5, -0.5) + 0.5,
  };
}

fragment float4 screenFragmentFunction(QuadVertex vert [[stage_in]],
                                       texture2d<float> offscreenResult [[texture(0)]],
                                       depth2d<float> offscreenResultDepth [[texture(1)]],
                                       constant struct FogUniforms &fogUniforms [[buffer(0)]]) {
  constexpr sampler smplr(coord::normalized);
  float4 color = offscreenResult.sample(smplr, vert.uv);
  return color;
};
