//
//  vertex_shader.metal
//  Minecraft
//
//  Created by Rohan van Klinken on 6/3/21.
//

#include <metal_stdlib>
using namespace metal;

struct InputVertex
{
  float3 position;
  float4 color;
};

struct OutputVertex
{
  float4 position [[position]];
  float4 color;
};

vertex OutputVertex vertexShader(uint vertexId [[vertex_id]], constant InputVertex *vertices [[buffer(0)]], constant float4x4 &worldToClipSpace [[buffer(1)]]) {
  InputVertex in = vertices[vertexId];
  float3 worldSpacePosition = in.position;
  
  OutputVertex out;
  
  out.position = float4(0.0, 0.0, 0.0, 1.0);
  out.position.xyz = worldSpacePosition;
  out.position.z = out.position.z;
  out.position = out.position * worldToClipSpace;
  out.color = vertices[vertexId].color;
  
  return out;
}

fragment float4 fragmentShader(OutputVertex in [[stage_in]]) {
  return in.color;
}
