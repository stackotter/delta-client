#include <metal_stdlib>
#include "ChunkTypes.metal"

using namespace metal;

constexpr sampler textureSampler (mag_filter::nearest, min_filter::nearest, mip_filter::linear);

vertex RasterizerData chunkVertexShader(uint vertexId [[vertex_id]],
                                        uint instanceId [[instance_id]],
                                        constant Vertex *vertices [[buffer(0)]],
                                        constant CameraUniforms &cameraUniforms [[buffer(1)]],
                                        constant ChunkUniforms &chunkUniforms [[buffer(2)]],
                                        constant TextureState *textureStates [[buffer(3)]]) {
  Vertex in = vertices[vertexId];
  RasterizerData out;

  float4 cameraSpacePosition = float4(in.x, in.y, in.z, 1.0) * chunkUniforms.transformation * cameraUniforms.framing;
  out.position = cameraSpacePosition * cameraUniforms.projection;
  out.cameraSpacePosition = float3(cameraSpacePosition / cameraSpacePosition.w);
  out.uv = float2(in.u, in.v);
  out.hasTexture = in.textureIndex != 65535;
  if (out.hasTexture) {
    out.textureState = textureStates[in.textureIndex];
  }
  out.isTransparent = in.isTransparent;
  out.tint = float4(in.r, in.g, in.b, in.a);
  out.skyLightLevel = in.skyLightLevel;
  out.blockLightLevel = in.blockLightLevel;

  return out;
}

fragment float4 chunkFragmentShader(RasterizerData in [[stage_in]],
                                    texture2d_array<float, access::sample> textureArray [[texture(0)]],
                                    constant uint8_t *lightMap [[buffer(0)]],
                                    constant float &time [[buffer(1)]],
                                    constant FogUniforms &fogUniforms [[buffer(2)]]) {
  // Sample the relevant texture slice
  float4 color;
  if (in.hasTexture) {
    color = textureArray.sample(textureSampler, in.uv, in.textureState.currentFrameIndex);
    if (in.textureState.nextFrameIndex != 65535) {
      float start = (float)in.textureState.previousUpdate;
      float end = (float)in.textureState.nextUpdate;
      float progress = (time - start) / (end - start);
      float4 nextColor = textureArray.sample(textureSampler, in.uv, in.textureState.nextFrameIndex);
      color = mix(color, nextColor, progress);
    }
  } else {
    color = float4(1, 1, 1, 1);
  }

  // Discard transparent fragments
  if (in.isTransparent && color.w < 0.33) {
    discard_fragment();
  }

  // Apply light level
  int index = in.skyLightLevel * 16 + in.blockLightLevel;
  float4 brightness;
  brightness.r = (float)lightMap[index * 4];
  brightness.g = (float)lightMap[index * 4 + 1];
  brightness.b = (float)lightMap[index * 4 + 2];
  brightness.a = 255;
  color *= brightness / 255.0;

  // A bit of branchless programming for you
  color = color * in.tint;

  // TODO: Rename isTransparent to isTranslucent (which would require inverting its value)
  // Here transparent means opaque or fully transparent (basically just 'not-translucent')
  color.w = color.w * !in.isTransparent // If not transparent, take the original alpha
          + in.isTransparent; // If transparent, make alpha 1

  float distance = length(in.cameraSpacePosition);

  float linearFogIntensity = smoothstep(fogUniforms.fogStart, fogUniforms.fogEnd, distance);
  float exponentialFogIntensity = clamp(1.0 - exp(-fogUniforms.fogDensity * distance), 0.0, 1.0);

  float fogIntensity = linearFogIntensity * fogUniforms.isLinear
                     + exponentialFogIntensity * !fogUniforms.isLinear;

  return color * (1.0 - fogIntensity) + fogUniforms.fogColor * fogIntensity;
}
