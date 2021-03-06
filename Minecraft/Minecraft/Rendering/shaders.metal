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
  float2 textureCoordinate;
};

struct RasteriserData
{
  float4 position [[position]];
  float2 textureCoordinate;
};

constexpr sampler textureSampler (mag_filter::nearest,
                                  min_filter::nearest);

vertex RasteriserData vertexShader(uint vertexId [[vertex_id]], constant Vertex *vertices [[buffer(0)]], constant float4x4 &modelToClipSpace [[buffer(1)]]) {
  Vertex in = vertices[vertexId];
  
  RasteriserData out;
  
  out.position = float4(0.0, 0.0, 0.0, 1.0);
  out.position.xyz = in.position;
  out.position = out.position * modelToClipSpace;
  
  out.textureCoordinate = in.textureCoordinate;
  
  return out;
}

fragment half4 fragmentShader(RasteriserData in [[stage_in]], texture2d<half> texture [[texture(3)]]) {
  return texture.sample(textureSampler, in.textureCoordinate);
}
