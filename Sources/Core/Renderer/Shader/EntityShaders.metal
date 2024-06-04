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
};

struct EntityRasterizerData {
  float4 position [[position]];
  float4 color;
};

vertex EntityRasterizerData entityVertexShader(constant EntityVertex *vertices [[buffer(0)]],
                                        constant CameraUniforms &cameraUniforms [[buffer(1)]],
                                        uint vertexId [[vertex_id]]) {
  EntityVertex in = vertices[vertexId];
  EntityRasterizerData out;

  out.position = float4(in.x, in.y, in.z, 1.0) * cameraUniforms.framing * cameraUniforms.projection;
  out.color = float4(in.r, in.g, in.b, 1.0);

  return out;
}

fragment float4 entityFragmentShader(EntityRasterizerData in [[stage_in]],
                                    texture2d_array<float, access::sample> textureArray [[texture(0)]]) {
  return in.color;
}
