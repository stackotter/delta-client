#include <metal_stdlib>
#include "GUITypes.metal"

using namespace metal;

constant const uint vertexIndexLookup[] = {0, 1, 2, 2, 3, 0};

vertex FragmentInput guiVertex(constant GUIUniforms &uniforms [[buffer(0)]],
                               constant GUIVertex *vertices [[buffer(1)]],
                               constant GUIElementUniforms &elementUniforms [[buffer(2)]],
                               uint vertexId [[vertex_id]],
                               uint instanceId [[instance_id]]) {
  uint index = vertexIndexLookup[vertexId % 6] + vertexId / 6 * 4;
  GUIVertex in = vertices[index];

  FragmentInput out;

  float2 position = in.position;
  position += elementUniforms.position;
  position *= uniforms.scale;

  float3 transformed = float3(position, 1) * uniforms.screenSpaceToNormalized;
  out.position = float4(transformed.xy, 0, transformed.z);

  out.uv = in.uv;
  out.tint = in.tint;
  out.textureIndex = in.textureIndex;

  return out;
}

constexpr sampler textureSampler (mag_filter::nearest, min_filter::nearest, mip_filter::linear);

fragment float4 guiFragment(FragmentInput in [[stage_in]],
                            texture2d_array<float, access::sample> textureArray [[texture(0)]]) {
  float4 color;
  if (in.textureIndex == 65535) {
    color = in.tint;
  } else {
    color = textureArray.sample(textureSampler, in.uv, in.textureIndex);
    if (color.w < 0.33) {
      discard_fragment();
    }
    color *= in.tint;
  }
  return color;
}
