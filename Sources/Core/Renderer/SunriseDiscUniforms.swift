import FirebladeMath

// TODO: Maybe to be more clear that it's not just sunrise, but sunset too, the
//   sunrise disc could be named more technically, like the RayleighScatteringDisc
//   or something (I don't like that one though, it loses clarity in other ways).
/// The uniforms for the sunrise/sunset disc.
public struct SunriseDiscUniforms {
  public var color: Vec4f
  public var transformation: Mat4x4f
}
