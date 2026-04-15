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
  uint8_t skyLightLevel;
  uint8_t blockLightLevel;
  uint16_t textureIndex;
};

struct EntityRasterizerData {
  float4 position [[position]];
  float4 color;
  float2 uv;
  uint8_t skyLightLevel;
  uint8_t blockLightLevel;
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
  out.skyLightLevel = in.skyLightLevel;
  out.blockLightLevel = in.blockLightLevel;

  return out;
}

constexpr sampler textureSampler (mag_filter::nearest, min_filter::nearest, mip_filter::linear);

fragment float4 entityFragmentShader(EntityRasterizerData in [[stage_in]],
                                    texture2d_array<float, access::sample> textureArray [[texture(0)]],
                                    constant uint8_t *lightMap [[buffer(0)]]) {
  float4 color;
  if (in.textureIndex == 65535) {
    color = in.color;
  } else {
    color = textureArray.sample(textureSampler, in.uv, in.textureIndex);
  }
  if (color.a < 0.3) {
    discard_fragment();
  }

  int index = in.skyLightLevel * 16 + in.blockLightLevel;
  float4 brightness;
  brightness.r = (float)lightMap[index * 4];
  brightness.g = (float)lightMap[index * 4 + 1];
  brightness.b = (float)lightMap[index * 4 + 2];
  brightness.a = 255;
  color *= brightness / 255.0;

  return color;
}
