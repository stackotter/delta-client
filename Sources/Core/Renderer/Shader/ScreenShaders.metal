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

fragment float4 screenFragmentFunction(QuadVertex v [[stage_in]],
                                       texture2d<float> outputImage [[texture(0)]]) {
  constexpr sampler smplr(coord::normalized);
  float4 cellColour = outputImage.sample(smplr, v.uv);
  return cellColour;
};

vertex QuadVertex screenVertexFunction(uint id [[vertex_id]]) {
  auto quadVertex = quadVertices[id];
  return {
    .position = float4(quadVertex, 1.0, 1.0),
    .uv =  quadVertex * float2(0.5, -0.5) + 0.5,
  };
}
