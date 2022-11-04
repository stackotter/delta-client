#include <metal_stdlib>

using namespace metal;

struct GUIVertex {
  float2 position;
  float2 uv;
  float4 tint;
  uint16_t textureIndex;
};

struct GUIUniforms {
  float3x3 screenSpaceToNormalized;
  float scale;
};

struct GUIElementUniforms {
  float2 position;
};

struct FragmentInput {
  float4 position [[position]];
  float2 uv;
  uint16_t textureIndex;
  float4 tint;
};
