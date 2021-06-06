//
//  vertex_shader.metal
//  DeltaClient
//
//  Created by Rohan van Klinken on 6/3/21.
//

#include <metal_stdlib>
using namespace metal;

struct Vertex
{
  float3 position;
  float2 uv;
  float light;
  uint16_t textureIndex;
  int8_t tintIndex;
};

struct RasteriserData
{
  float4 position [[position]];
  float2 uv;
  float light;
  uint textureIndex;
  int8_t tintIndex;
};

struct WorldUniforms
{
  float4x4 worldToClipSpace;
};

struct ChunkUniforms
{
  float4x4 modelToWorld;
};

constexpr sampler textureSampler (mag_filter::nearest, min_filter::nearest);

vertex RasteriserData chunkVertexShader(uint vertexId [[vertex_id]], constant Vertex *vertices [[buffer(0)]],
                                        constant WorldUniforms &worldUniforms [[buffer(1)]],
                                        constant ChunkUniforms &chunkUniforms [[buffer(2)]]) {
  // get vertex data
  Vertex in = vertices[vertexId];
  RasteriserData out;
  out.position = float4(0.0, 0.0, 0.0, 1.0);
  out.position.xyz = in.position;
  
  // apply matrices
  out.position = out.position * chunkUniforms.modelToWorld * worldUniforms.worldToClipSpace;
  
  // pass texture information through to fragment shader untouched
  out.uv = in.uv;
  out.light = in.light;
  out.textureIndex = in.textureIndex;
  out.tintIndex = in.tintIndex;
  
  return out;
}

fragment float4 chunkFragmentShader(RasteriserData in [[stage_in]],
                                    texture2d_array<float, access::sample> textureArray [[texture(0)]]) {
  // sample the relevant texture slice
  float4 color = textureArray.sample(textureSampler, in.uv, in.textureIndex);
  
  // discard transparent fragments
  if (color.w == 0) {
    discard_fragment();
  }
  
  // tint any tinted block with a hardcoded tint for now (some kinda green grass colour)
  if (in.tintIndex != -1) {
    color = color * float4(0.53, 0.75, 0.38, 1.0);
  }
  
  color = color * in.light;
  
  return color;
}
