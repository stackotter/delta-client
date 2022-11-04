#include <metal_stdlib>
using namespace metal;

struct Vertex {
  float x;
  float y;
  float z;
  float r;
  float g;
  float b;
};

struct RasterizerData {
  float4 position [[position]];
  float4 color;
};

struct Uniforms {
  float4x4 transformation;
};

vertex RasterizerData entityVertexShader(constant Vertex *vertices [[buffer(0)]],
                                        constant Uniforms &uniforms [[buffer(1)]],
                                        constant Uniforms *instanceUniforms [[buffer(2)]],
                                        uint vertexId [[vertex_id]],
                                        uint instanceId [[instance_id]]) {
  Vertex in = vertices[vertexId];
  RasterizerData out;

  out.position = float4(in.x, in.y, in.z, 1.0) * instanceUniforms[instanceId].transformation * uniforms.transformation;
  out.color = float4(in.r, in.g, in.b, 1);

  return out;
}

fragment float4 entityFragmentShader(RasterizerData in [[stage_in]],
                                    texture2d_array<float, access::sample> textureArray [[texture(0)]]) {
  return in.color;
}
