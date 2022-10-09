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
  uint16_t textureIndex;
  bool isTransparent;
};

struct RasterizerData {
  float4 position [[position]];
  float2 uv;
  float4 tint;
  uint16_t textureIndex; // Index of texture to use
  bool isTransparent;
};

struct Uniforms {
  float4x4 transformation;
};

// Also used for translucent textures for now
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

  return out;
}

fragment float4 chunkFragmentShader(RasterizerData in [[stage_in]],
                                    texture2d_array<float, access::sample> textureArray [[texture(0)]]) {
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

  // A bit of branchless programming
  color = color * in.tint;
  color.w = color.w * !in.isTransparent // If not transparent, take the original alpha
          + in.isTransparent; // If transparent, make alpha 1

  return color;
}


constant float2 quadVertices[] = {
     float2(-1.0,  1.0),
     float2(-1.0, -1.0),
     float2( 1.0, -1.0),
     float2(-1.0,  1.0),
     float2( 1.0,  1.0),
     float2( 1.0, -1.0)
 };

 struct QuadVertex {
     float4 position [[position]];
     float2 uv;
 };


 fragment float4 screenFragmentFunction(QuadVertex v [[stage_in]],
                                  texture2d <float> outputImage [[ texture(0) ]]) {

     constexpr sampler smplr(coord::normalized);
     float4 cellColour = outputImage.sample(smplr, v.uv);
     return cellColour;
 };


 vertex QuadVertex screenVertexFunction(uint id [[vertex_id]]) {

     auto quadVertex = quadVertices[id];

     return {
         .position = float4(quadVertex, 1.0, 1.0),
         .uv =  quadVertex * float2(0.5, -0.5) + 0.5,
     };
 }
