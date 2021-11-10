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
  uint16_t textureIndex;
  bool isTransparent;
};

struct RasteriserData {
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

vertex RasteriserData chunkVertexShader(uint vertexId [[vertex_id]], constant Vertex *vertices [[buffer(0)]],
                                        constant Uniforms &worldUniforms [[buffer(1)]],
                                        constant Uniforms &chunkUniforms [[buffer(2)]]) {
  Vertex in = vertices[vertexId];
  RasteriserData out;
  
  out.position = float4(in.x, in.y, in.z, 1.0) * chunkUniforms.transformation * worldUniforms.transformation;
  out.uv = float2(in.u, in.v);
  out.textureIndex = in.textureIndex;
  out.isTransparent = in.isTransparent;
  out.tint = float4(in.r, in.g, in.b, 1);
  
  return out;
}

fragment float4 chunkFragmentShader(RasteriserData in [[stage_in]],
                                    texture2d_array<float, access::sample> textureArray [[texture(0)]]) {
  // sample the relevant texture slice
  float4 color;
  color = textureArray.sample(textureSampler, in.uv, in.textureIndex);
  color = color * in.tint;
  
  // discard transparent fragments
  if (in.isTransparent && color.w < 0.33) {
    discard_fragment();
  }
    
  if (in.isTransparent) {
      color.w = 1;
  }
  
  return color;
}
