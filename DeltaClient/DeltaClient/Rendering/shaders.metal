//
//  vertex_shader.metal
//  Minecraft
//
//  Created by Rohan van Klinken on 6/3/21.
//

#include <metal_stdlib>
using namespace metal;

struct Vertex
{
  float3 position;
  float2 uv;
  uint16_t textureIndex;
  int8_t tintIndex;
};

struct RasteriserData
{
  float4 position [[position]];
  float2 uv;
  uint textureIndex;
  int8_t tintIndex;
};

constexpr sampler textureSampler (mag_filter::nearest,
                                  min_filter::nearest);

vertex RasteriserData vertexShader(uint vertexId [[vertex_id]], constant Vertex *vertices [[buffer(0)]], constant float4x4 &modelToClipSpace [[buffer(1)]]) {
  Vertex in = vertices[vertexId];
  
  RasteriserData out;
  
  out.position = float4(0.0, 0.0, 0.0, 1.0);
  out.position.xyz = in.position;
  out.position = out.position * modelToClipSpace;
  
  out.uv = in.uv;
  out.textureIndex = in.textureIndex;
  out.tintIndex = in.tintIndex;
  
  return out;
}

fragment float4 fragmentShader(RasteriserData in [[stage_in]], texture2d_array<float, access::sample> textureArray [[texture(0)]]) {
  float4 color = textureArray.sample(textureSampler, in.uv, in.textureIndex);
  if (color.w != 1) {
    discard_fragment();
  }
  if (in.tintIndex != -1) {
    color = color * float4(0.53, 0.75, 0.38, 1.0);
  }
  return color;
}
