#include <metal_stdlib>
#include "GUITypes.metal"

using namespace metal;

vertex FragmentInput guiVertex(constant GUIQuadVertex *vertices [[buffer(0)]],
                               constant GUIUniforms &uniforms [[buffer(1)]],
                               constant GUIElementUniforms &elementUniforms [[buffer(2)]],
                               constant GUIQuadInstance *quads [[buffer(3)]],
                               uint vertexId [[vertex_id]],
                               uint instanceId [[instance_id]]) {
  GUIQuadVertex in = vertices[vertexId];

  GUIQuadInstance quad = quads[instanceId];
  FragmentInput output;

  float2 position = in.position;
  position.x *= quad.size.x;
  position.y *= quad.size.y;
  position += quad.position;
  position += elementUniforms.position;
  position *= uniforms.scale;

  float3 transformed = float3(position, 1) * uniforms.screenSpaceToNormalized;
  output.position = float4(transformed.xy, 0, transformed.z);

  output.uv = in.uv;
  output.uv.x *= quad.uvSize.x;
  output.uv.x += quad.uvMin.x;
  output.uv.y *= quad.uvSize.y;
  output.uv.y += quad.uvMin.y;

  output.textureIndex = quad.textureIndex;
  return output;
}

constexpr sampler textureSampler (mag_filter::nearest, min_filter::nearest, mip_filter::linear);

fragment float4 guiFragment(FragmentInput in [[stage_in]],
                            texture2d_array<float, access::sample> textureArray [[texture(0)]]) {
    float4 color = textureArray.sample(textureSampler, in.uv, in.textureIndex);
    if (color.w == 0) {
        discard_fragment();
    }
    return color;
}
