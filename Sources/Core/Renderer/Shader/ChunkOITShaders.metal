#include <metal_stdlib>
#include "ChunkTypes.metal"

using namespace metal;

// These shaders are used in the order independent transparency pipeline based off this blog
// article: https://casual-effects.blogspot.com/2015/03/implemented-weighted-blended-order.html?m=1
// The vertex shader used in this pipeline is just the regular one in ChunkShaders.metal
// Compositing is performed using chunkOITCompositingVertexShader and chunkOITFragmentShader

struct FragmentOut {
  float4 accumulation [[ color(1) ]];
  float revealage [[ color(2) ]];
};

constexpr sampler textureSampler (mag_filter::nearest, min_filter::nearest, mip_filter::linear);

constant float precomputedWeight = 0.286819249;

fragment FragmentOut chunkOITFragmentShader(RasterizerData in [[stage_in]],
                                            texture2d_array<float, access::sample> textureArray [[texture(0)]],
                                            constant uint8_t *lightMap [[buffer(0)]],
                                            constant float &time [[buffer(1)]],
                                            constant FogUniforms &fogUniforms [[buffer(2)]]) {
  // Sample the relevant texture slice
  FragmentOut out;
  float4 color = textureArray.sample(textureSampler, in.uv, in.textureState.currentFrameIndex);
  if (in.textureState.nextFrameIndex != 65535) {
    float start = (float)in.textureState.previousUpdate;
    float end = (float)in.textureState.nextUpdate;
    float progress = (time - start) / (end - start);
    float4 nextColor = textureArray.sample(textureSampler, in.uv, in.textureState.nextFrameIndex);
    color = mix(color, nextColor, progress);
  }

  // Apply light level
  int index = in.skyLightLevel * 16 + in.blockLightLevel;
  float4 brightness;
  brightness.r = (float)lightMap[index * 4];
  brightness.g = (float)lightMap[index * 4 + 1];
  brightness.b = (float)lightMap[index * 4 + 2];
  brightness.a = 255;

  color *= brightness / 255.0;
  color *= in.tint;

  // Apply distance fog
  float distance = length(in.cameraSpacePosition);
  float linearFogIntensity = smoothstep(fogUniforms.fogStart, fogUniforms.fogEnd, distance);
  float exponentialFogIntensity = clamp(1.0 - exp(-fogUniforms.fogDensity * distance), 0.0, 1.0);
  float fogIntensity = linearFogIntensity * fogUniforms.isLinear
                     + exponentialFogIntensity * !fogUniforms.isLinear;
  color.rgb = color.rgb * (1.0 - fogIntensity) + fogUniforms.fogColor * fogIntensity;

  // As the fog approaches an intensity of 1.0, the alpha of the fragment has to increase to 1.0
  // as well so that the fragment disappears into the fog. Otherwise the fragment is still visible
  // even once everything around it has disappeared into the fog (some weirdness with additive blending
  // during the compositing step). Cubing the intensity to curve it a bit more makes it look a bit
  // more correct (still looks a bit odd though).
  float fogAlphaIntensity = fogIntensity * fogIntensity * fogIntensity * fogIntensity;
  color.a = color.a * (1.0 - fogAlphaIntensity) + fogAlphaIntensity;

  // Premultiply alpha
  color.rgb *= color.a;

  // Order independent transparency code adapted from https://casual-effects.blogspot.com/2015/03/implemented-weighted-blended-order.html?m=1
  // I have changed the maths a lot to get it working well at all. I've hardcoded the depth for now
  // and it seems to be working quite well.

  // This code was used to calculate z which was used in weight calculations. This had super weird
  // artifacts and it turns out that just hardcoding the depth to 16 works way better than any depth
  // weighting algorithms I have tried. The precomputedWeight is calculated using Equation 7 from
  // the 2013 paper by Morgan mcGuire and Louis Bavoil of NVIDIA: https://jcgt.org/published/0002/02/09/
  //
  //   float d = in.position.z;
  //   float far = 400;
  //   float near = 0.04;
  //   float z = (far * near) / (d * (far - near) - far) + 32;
  //
  //   constant float z = 16;
  //   constant float zCubed = z * z * z;
  //   constant float precomputedWeight = max(1e-2, min(3e3, 10 / (1e-5 + zCubed / 125 + zCubed * zCubed / 8e6)));

  float w = color.a * precomputedWeight;
  out.accumulation = color * w;
  out.revealage = color.a;

  return out;
}

// You're welcome for the alignment
constant float4 screenCorners[6] = {
  float4( 1,  1, 0, 1),
  float4( 1, -1, 0, 1),
  float4(-1,  1, 0, 1),
  float4( 1, -1, 0, 1),
  float4(-1, -1, 0, 1),
  float4(-1,  1, 0, 1)
};

vertex OITCompositingRasterizerData chunkOITCompositingVertexShader(uint vertexId [[vertex_id]]) {
  OITCompositingRasterizerData out;
  out.position = screenCorners[vertexId];

  return out;
}

fragment float4 chunkOITCompositingFragmentShader(OITCompositingRasterizerData in [[stage_in]],
                                                  float4 accumulation [[color(1)]],
                                                  float revealage [[color(2)]]) {
  return float4(accumulation.rgb / max(min(accumulation.a, 5e4), 1e-4), 1 - revealage);
}
