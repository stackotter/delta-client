#include <metal_stdlib>
#include "ChunkTypes.metal"

using namespace metal;

struct EntityVertex {
  float x;
  float y;
  float z;
  float r;
  float g;
  float b;
  float u;
  float v;
  uint16_t textureIndex;
};

struct EntityRasterizerData {
  float4 position [[position]];
  float4 color;
  float2 uv;
  uint16_t textureIndex;
};

vertex EntityRasterizerData entityVertexShader(constant EntityVertex *vertices [[buffer(0)]],
                                        constant CameraUniforms &cameraUniforms [[buffer(1)]],
                                        uint vertexId [[vertex_id]]) {
  EntityVertex in = vertices[vertexId];
  EntityRasterizerData out;

  out.position = float4(in.x, in.y, in.z, 1.0) * cameraUniforms.framing * cameraUniforms.projection;
  out.color = float4(in.r, in.g, in.b, 1.0);
  out.uv = float2(in.u, in.v);
  out.textureIndex = in.textureIndex;

  return out;
}

constexpr sampler textureSampler (mag_filter::nearest, min_filter::nearest, mip_filter::linear);

fragment float4 entityFragmentShader(EntityRasterizerData in [[stage_in]],
                                    texture2d_array<float, access::sample> textureArray [[texture(0)]]) {
  float4 color;
  if (in.textureIndex == 65535) {
    color = in.color;
  } else {
    color = textureArray.sample(textureSampler, in.uv, in.textureIndex);
  }
  if (color.a < 0.3) {
    discard_fragment();
  }
  return color;
}
