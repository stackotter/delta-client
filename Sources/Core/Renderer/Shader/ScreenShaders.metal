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
  float nearPlane;
  float farPlane;
  float fogStart;
  float fogEnd;
  float4 fogColor;
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

  float fogIntensity = smoothstep(fogUniforms.fogStart, fogUniforms.fogEnd, distance);

  return color * (1.0 - fogIntensity) + fogUniforms.fogColor * fogIntensity;
};
