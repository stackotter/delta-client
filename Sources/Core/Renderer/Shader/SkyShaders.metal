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
  float size;
  float verticalOffset;
  float4x4 playerToClip;
};

vertex SkyPlaneVertex skyPlaneVertex(uint id [[vertex_id]],
                                     constant float3 *vertices [[buffer(0)]],
                                     constant struct SkyPlaneUniforms &uniforms [[buffer(1)]]) {
  float3 position = vertices[id];
  position *= uniforms.size / 2;
  position += float3(0, uniforms.verticalOffset, 0);
  return {
    .transformedPosition = float4(position, 1.0) * uniforms.playerToClip,
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

struct CelestialBodyVertex {
  float4 position [[position]];
  float2 uv;
  uint16_t index;
};

struct CelestialBodyUniforms {
  float4x4 transformation;
  uint16_t textureIndex;
  float2 uvPosition;
  float2 uvSize;
  uint8_t type;
};

#define SUN_TYPE 0
#define MOON_TYPE 1

constexpr sampler textureSampler (mag_filter::nearest, min_filter::nearest, mip_filter::linear);

vertex CelestialBodyVertex celestialBodyVertex(uint id [[vertex_id]],
                                               constant float3 *vertices [[buffer(0)]],
                                               constant struct CelestialBodyUniforms &uniforms [[buffer(1)]]) {
  float3 position = vertices[id];

  // The quad goes from -1 to 1 along the x and z axes, simply shift the xz coordinates to get the uvs.
  float2 uv = position.xz / 2.0 + float2(0.5, 0.5);
  uv *= uniforms.uvSize;
  uv += uniforms.uvPosition;

  return {
    .position = float4(position, 1.0) * uniforms.transformation,
    .uv = uv,
    .index = uniforms.textureIndex
  };
}

fragment float4 celestialBodyFragment(CelestialBodyVertex in [[stage_in]],
                                      texture2d_array<float, access::sample> textureArray [[texture(0)]]) {
  return textureArray.sample(textureSampler, in.uv, in.index);
}

struct StarVertex {
  float4 position [[position]];
};

struct StarUniforms {
  float4x4 transformation;
  float brightness;
};

vertex StarVertex starVertex(uint id [[vertex_id]],
                             constant float3 *vertices [[buffer(0)]],
                             constant struct StarUniforms &uniforms [[buffer(1)]]) {
  float3 position = vertices[id];

  return {
    .position = float4(position, 1.0) * uniforms.transformation,
  };
}

fragment float4 starFragment(StarVertex in [[stage_in]],
                             constant struct StarUniforms &uniforms [[buffer(0)]]) {
  return float4(uniforms.brightness);
}
