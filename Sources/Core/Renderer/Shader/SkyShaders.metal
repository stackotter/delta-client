#include <metal_stdlib>
using namespace metal;

struct SkyPlaneVertex {
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

vertex SkyPlaneVertex skyPlaneVertex(uint id [[vertex_id]],
                                     constant float3 *vertices [[buffer(0)]],
                                     constant struct SkyPlaneUniforms &uniforms [[buffer(1)]]) {
  float3 position = vertices[id];
  return {
    .transformedPosition = float4(position, 1.0) * uniforms.transformation,
    .playerSpacePosition = position
  };
}

fragment float4 skyPlaneFragment(SkyPlaneVertex vert [[stage_in]],
                                 constant struct SkyPlaneUniforms &uniforms [[buffer(0)]]) {
  float distance = length(vert.playerSpacePosition);
  float fogIntensity = smoothstep(uniforms.fogStart, uniforms.fogEnd, distance);
  return uniforms.skyColor * (1.0 - fogIntensity) + uniforms.fogColor * fogIntensity;
}

struct SunriseDiscVertex {
  float4 position [[position]];
  float4 color;
};

struct SunriseDiscUniforms {
  float4 color;
  float4x4 transformation;
};

vertex SunriseDiscVertex sunriseDiscVertex(uint id [[vertex_id]],
                                           constant float3 *vertices [[buffer(0)]],
                                           constant struct SunriseDiscUniforms &uniforms [[buffer(1)]]) {
  float3 inPosition = vertices[id];
  float4 color = uniforms.color;

  // Modify disc tilt based on color alpha
  inPosition.y *= uniforms.color.a;

  // Set the ring vertices' alphas to 0
  color.a *= id == 0;

  float4 outPosition = float4(inPosition, 1.0) * uniforms.transformation;

  return {
    .position = outPosition,
    .color = color
  };
}

fragment float4 sunriseDiscFragment(SunriseDiscVertex vert [[stage_in]]) {
  return vert.color;
}
