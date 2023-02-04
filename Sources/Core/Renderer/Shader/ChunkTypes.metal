#include <metal_stdlib>

using namespace metal;

struct Vertex {
  float x;
  float y;
  float z;
  float u;
  float v;
  float r;
  float g;
  float b;
  float a;
  uint8_t skyLightLevel; // TODO: pack sky and block light into a single uint8 to reduce size of vertex
  uint8_t blockLightLevel;
  uint16_t textureIndex;
  bool isTransparent;
};

struct RasterizerData {
  float4 position [[position]];
  float2 uv;
  float4 tint;
  uint16_t textureIndex; // Index of texture to use
  bool isTransparent;
  uint8_t skyLightLevel;
  uint8_t blockLightLevel;
};

struct Uniforms {
  float4x4 transformation;
};

struct OITCompositingRasterizerData {
  float4 position [[position]];
};
