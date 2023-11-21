import FirebladeMath

/// Uniforms used to render distance fog.
struct FogUniforms {
  var inverseProjection: Mat4x4f
  var nearPlane: Float
  var farPlane: Float
  var fogStart: Float
  var fogEnd: Float
  var fogColor: Vec4f
}
