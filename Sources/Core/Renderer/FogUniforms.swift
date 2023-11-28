import FirebladeMath

/// Uniforms used to render distance fog.
struct FogUniforms {
  var fogColor: Vec3f
  var fogStart: Float
  var fogEnd: Float
  var fogDensity: Float
  var isLinear: Bool
}
