#include <metal_stdlib>
using namespace metal;

struct Vertex {
  float4 transformedPosition [[position]];
  // The position in the world's coordinate system but centered on the player.
  float3 playerSpacePosition;
};

struct SkyPlaneUniforms {
  float4 skyColor;
  float4 fogColor;
  float fogStart;
  float fogEnd;
  float4x4 transformation;
};

vertex Vertex skyVertex(uint id [[vertex_id]],
                        constant float3 *vertices [[buffer(0)]],
                        constant struct SkyPlaneUniforms &uniforms [[buffer(1)]]) {
  float3 position = vertices[id];
  return {
    .transformedPosition = float4(position, 1.0) * uniforms.transformation,
    .playerSpacePosition = position
  };
}

fragment float4 skyFragment(Vertex vert [[stage_in]],
                            constant struct SkyPlaneUniforms &uniforms [[buffer(0)]]) {
  float distance = length(vert.playerSpacePosition);
  float fogIntensity = smoothstep(uniforms.fogStart, uniforms.fogEnd, distance);
  return uniforms.skyColor * (1.0 - fogIntensity) + uniforms.fogColor * fogIntensity;
}
