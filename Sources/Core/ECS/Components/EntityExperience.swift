/// An entity's experience level.
public struct EntityExperience {
  /// The entity's total xp.
  public var experience: Int
  /// The entity's xp level (displayed above the xp bar).
  public var experienceLevel: Int
  /// The entity's experience bar progress.
  public var experienceBarProgress: Float
  
  /// Creates an entity's xp state.
  /// - Parameters:
  ///   - experience: Defaults to 0.
  ///   - experienceLevel: Defaults to 0.
  ///   - experienceBarProgress: Defaults to 0.
  public init(experience: Int = 0, experienceLevel: Int = 0, experienceBarProgress: Float = 0) {
    self.experience = experience
    self.experienceLevel = experienceLevel
    self.experienceBarProgress = experienceBarProgress
  }
}
