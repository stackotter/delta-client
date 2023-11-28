#include <metal_stdlib>

using namespace metal;

struct TextureState {
  uint16_t currentFrameIndex;
  uint16_t nextFrameIndex;
  uint32_t previousUpdate;
  uint32_t nextUpdate;
};

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
  float3 cameraSpacePosition;
  float2 uv;
  float4 tint;
  TextureState textureState;
  bool hasTexture;
  bool isTransparent;
  uint8_t skyLightLevel;
  uint8_t blockLightLevel;
};

struct CameraUniforms {
  float4x4 framing;
  float4x4 projection;
};

struct ChunkUniforms {
  float4x4 transformation;
};

struct OITCompositingRasterizerData {
  float4 position [[position]];
};

struct FogUniforms {
  float4 fogColor;
  float fogStart;
  float fogEnd;
  float fogDensity;
  bool isLinear;
};
