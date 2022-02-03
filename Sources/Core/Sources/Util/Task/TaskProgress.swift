/// Tracks a task's progress.
public struct TaskProgress<Step: TaskStep> {
  // MARK: Public properties
  
  public var message: String {
    currentStep.message
  }
  
  /// The current progress from 0 to 1.
  public var progress: Double {
    var progress: Double = 0
    for step in Step.allCases {
      if step == currentStep {
        break
      }
      progress += step.relativeDuration
    }
    progress += currentStep.relativeDuration * stepProgress
    return progress / Self.totalTaskDuration
  }
  
  // MARK: Private properties
  
  private var currentStep = Step.allCases.first!
  
  private var stepProgress: Double = 1
  
  /// The total combined duration of all steps. There is no unit, it is just the sum of relative durations.
  private static var totalTaskDuration: Double {
    Step.allCases.map {
      $0.relativeDuration
    }.reduce(0, { $0 + $1 })
  }
  
  // MARK: Init
  
  public init() {}
  
  // MARK: Public methods
  
  /// Update the task's progress.
  public mutating func update(to step: Step, stepProgress: Double = 0) {
    self.currentStep = step
    self.stepProgress = stepProgress
  }
}
