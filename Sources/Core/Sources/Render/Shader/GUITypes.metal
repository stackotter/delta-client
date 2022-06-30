#include <metal_stdlib>

using namespace metal;

struct GUIQuadVertex {
  float2 position;
  float2 uv;
};

struct GUIUniforms {
  float3x3 screenSpaceToNormalized;
  float scale;
};

struct GUIElementUniforms {
  float2 position;
};

struct GUIQuadInstance {
  float2 position;
  float2 size;
  float2 uvMin;
  float2 uvSize;
  uint16_t textureIndex;
  float3 tint;
};

struct FragmentInput {
  float4 position [[position]];
  float2 uv;
  uint16_t textureIndex;
  float3 tint;
};
