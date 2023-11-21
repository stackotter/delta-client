#include <metal_stdlib>
using namespace metal;

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

struct FogUniforms {
  float4x4 inverseProjection;
  float4 fogColor;
  float nearPlane;
  float farPlane;
  float fogStart;
  float fogEnd;
  float fogDensity;
  bool isLinear;
};

vertex QuadVertex screenVertexFunction(uint id [[vertex_id]]) {
  auto quadVertex = quadVertices[id];
  return {
    .position = float4(quadVertex, 1.0, 1.0),
    .uv =  quadVertex * float2(0.5, -0.5) + 0.5,
  };
}

fragment float4 screenFragmentFunction(QuadVertex vert [[stage_in]],
                                       texture2d<float> offscreenResult [[texture(0)]],
                                       depth2d<float> offscreenResultDepth [[texture(1)]],
                                       constant struct FogUniforms &fogUniforms [[buffer(0)]]) {
  constexpr sampler smplr(coord::normalized);
  float z = offscreenResultDepth.sample(smplr, vert.uv);
  float4 color = offscreenResult.sample(smplr, vert.uv);

  float far = fogUniforms.farPlane;
  float near = fogUniforms.nearPlane;
  float trueZ = far * near / (far - near) / (far / (far - near) - z);
  float2 xy = (vert.uv - 0.5) * float2(2.0, -2.0);
  float4 screenspacePosition = float4(xy, z, 1.0) * (-trueZ);
  float4 cameraspacePosition = screenspacePosition * fogUniforms.inverseProjection;

  float distance = length(cameraspacePosition.xyz);

  float linearFogIntensity = smoothstep(fogUniforms.fogStart, fogUniforms.fogEnd, distance);
  float exponentialFogIntensity = clamp(1.0 - exp(-fogUniforms.fogDensity * distance), 0.0, 1.0);

  // Only render fog if the pixel is part of the terrain (the sky box already has its own fog)
  float fogIntensity = (z != 1) *
    (
      linearFogIntensity * fogUniforms.isLinear +
      exponentialFogIntensity * !fogUniforms.isLinear
    );

  return color * (1.0 - fogIntensity) + fogUniforms.fogColor * fogIntensity;
};
