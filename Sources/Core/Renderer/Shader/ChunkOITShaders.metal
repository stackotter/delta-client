#include <metal_stdlib>
#include "ChunkTypes.metal"

using namespace metal;

// These shaders are used in the order independent transparency pipeline based off this blog
// article: https://casual-effects.blogspot.com/2015/03/implemented-weighted-blended-order.html?m=1
// The vertex shader used in this pipeline is just the regular one in ChunkShaders.metal
// Compositing is performed using chunkOITCompositingVertexShader and chunkOITFragmentShader

struct FragmentOut {
  float4 accumulation [[ color(1) ]];
  float revealage [[ color(2) ]];
};

constexpr sampler textureSampler (mag_filter::nearest, min_filter::nearest, mip_filter::linear);

fragment FragmentOut chunkOITFragmentShader(RasterizerData in [[stage_in]],
                                                     texture2d_array<float, access::sample> textureArray [[texture(0)]],
                                                     constant uint8_t *lightMap [[buffer(0)]]) {
  // Sample the relevant texture slice
  FragmentOut out;
  float4 color = textureArray.sample(textureSampler, in.uv, in.textureIndex);

  // Apply light level
  int index = in.skyLightLevel * 16 + in.blockLightLevel;
  float4 brightness;
  brightness.r = (float)lightMap[index * 4];
  brightness.g = (float)lightMap[index * 4 + 1];
  brightness.b = (float)lightMap[index * 4 + 2];
  brightness.a = 255;

  color *= brightness / 255.0;
  color *= in.tint;

  // Order independent transparency code adapted from https://casual-effects.blogspot.com/2015/03/implemented-weighted-blended-order.html?m=1

  float depthFactor = 1 - in.position.z;

  float w = color.a * max(1e-2, 3e3 * depthFactor * depthFactor * depthFactor);
  out.accumulation = color * w;
  out.revealage = color.a;

  return out;
}

// You're welcome for the alignment
constant float4 screenCorners[6] = {
  float4( 1,  1, 0, 1),
  float4( 1, -1, 0, 1),
  float4(-1,  1, 0, 1),
  float4( 1, -1, 0, 1),
  float4(-1, -1, 0, 1),
  float4(-1,  1, 0, 1)
};

vertex OITCompositingRasterizerData chunkOITCompositingVertexShader(uint vertexId [[vertex_id]]) {
  OITCompositingRasterizerData out;
  out.position = screenCorners[vertexId];

  return out;
}

fragment float4 chunkOITCompositingFragmentShader(RasterizerData in [[stage_in]],
                                                  float4 accumulation [[color(1)]],
                                                  float revealage [[color(2)]]) {
  return float4(accumulation.rgb / max(accumulation.a, 0.00001), 1 - revealage);
}
