#include <metal_stdlib>
#include "ChunkTypes.metal"

using namespace metal;

constexpr sampler textureSampler (mag_filter::nearest, min_filter::nearest, mip_filter::linear);

vertex RasterizerData chunkVertexShader(uint vertexId [[vertex_id]],
                                        uint instanceId [[instance_id]],
                                        constant Vertex *vertices [[buffer(0)]],
                                        constant Uniforms &worldUniforms [[buffer(1)]],
                                        constant Uniforms &chunkUniforms [[buffer(2)]],
                                        constant Uniforms *instanceUniforms [[buffer(3)]]) {
  Uniforms instance = instanceUniforms[instanceId];
  Vertex in = vertices[vertexId];
  RasterizerData out;

  out.position = float4(in.x, in.y, in.z, 1.0) * instance.transformation * chunkUniforms.transformation * worldUniforms.transformation;
  out.uv = float2(in.u, in.v);
  out.textureIndex = in.textureIndex;
  out.isTransparent = in.isTransparent;
  out.tint = float4(in.r, in.g, in.b, in.a);
  out.skyLightLevel = in.skyLightLevel;
  out.blockLightLevel = in.blockLightLevel;

  return out;
}

fragment float4 chunkFragmentShader(RasterizerData in [[stage_in]],
                                    texture2d_array<float, access::sample> textureArray [[texture(0)]],
                                    constant uint8_t *lightMap [[buffer(0)]]) {
  // TODO: Remove isTransparent, it's not needed anymore. All vertices in this shader can be assumed
  // to be transparent.

  // Sample the relevant texture slice
  float4 color;
  if (in.textureIndex == 65535) {
    color = float4(1, 1, 1, 1);
  } else {
    color = textureArray.sample(textureSampler, in.uv, in.textureIndex);
  }

  // Discard transparent fragments
  if (in.isTransparent && color.w < 0.33) {
    discard_fragment();
  }

  // Apply light level
  int index = in.skyLightLevel * 16 + in.blockLightLevel;
  float4 brightness;
  brightness.r = (float)lightMap[index * 4];
  brightness.g = (float)lightMap[index * 4 + 1];
  brightness.b = (float)lightMap[index * 4 + 2];
  brightness.a = 255;
  color *= brightness / 255.0;

  // A bit of branchless programming for you
  color = color * in.tint;
  color.w = color.w * !in.isTransparent // If not transparent, take the original alpha
          + in.isTransparent; // If transparent, make alpha 1

  return color;
}
