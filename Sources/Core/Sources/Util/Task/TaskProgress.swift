// TODO: Change back to a struct if possible. It seems like it's easiest to have it
//   as a class for the nested progress helper methods. Perhaps non-copyable types
//   would allow us to work around that while maintaining an ergonomic API.
/// Tracks a task's progress.
public final class TaskProgress<Step: TaskStep> {
  /// The current progress message.
  public var message: String {
    customMessage ?? currentStep?.message ?? "Loading"
  }

  /// The current progress from 0 to 1.
  public var progress: Double {
    guard let currentStep = currentStep else {
      return 0
    }

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

  /// The current step. `nil` when initially created.
  public private(set) var currentStep: Step?

  /// The progress of the current step from 0 to 1.
  public private(set) var stepProgress: Double = 0

  /// A custom message overriding the message of the current step. Useful when
  /// nesting tasks.
  public private(set) var customMessage: String?

  private var changeHandler: ((TaskProgress<Step>) -> Void)?

  /// The total combined duration of all steps. There is no unit, it is just the sum of relative durations.
  private static var totalTaskDuration: Double {
    Step.allCases.map {
      $0.relativeDuration
    }.reduce(into: 0, { $0 += $1 })
  }

  /// Creates a new task progress tracker. Initially has no current step.
  public init() {}

  /// Adds a step handler to the progress. The handler gets run whenever the current
  /// step changes (not triggered if the step progress changes while the step remains
  /// the same). Can be called multiple times to create a chain of handlers.
  public func onChange(action: @escaping (TaskProgress<Step>) -> Void) -> TaskProgress<Step> {
    if let existingHandler = changeHandler {
      changeHandler = { progress in
        existingHandler(progress)
        action(progress)
      }
    } else {
      changeHandler = action
    }
    return self
  }

  /// Update the task's progress.
  public func update(
    to step: Step,
    stepProgress: Double = 0,
    customMessage: String? = nil
  ) {
    currentStep = step
    self.stepProgress = stepProgress
    self.customMessage = customMessage
    changeHandler?(self)
  }

  /// Performs a step and returns its result.
  public func perform<R>(_ step: Step, action: () throws -> R) rethrows -> R {
    update(to: step, stepProgress: 0)
    return try action()
  }

  /// Performs a step if a condition holds. Returns the result of the step if it is run.
  public func perform<R>(
    _ step: Step,
    if condition: Bool, action: () throws -> R
  ) rethrows -> R? {
    guard condition else {
      return nil
    }

    update(to: step, stepProgress: 0)
    return try action()
  }

  /// Performs a step and runs an action if it fails. Returns the result of the step if it succeeds.
  public func perform<R>(
    _ step: Step,
    action: () throws -> R, handleError: (any Error) -> Void
  ) -> R? {
    update(to: step, stepProgress: 0)
    do {
      return try action()
    } catch {
      handleError(error)
      return nil
    }
  }

  /// Performs a step with a nested task progress tracker.
  public func perform<InnerStep: TaskStep, R>(
    _ step: Step,
    action: (@escaping (TaskProgress<InnerStep>) -> Void) throws -> R
  ) rethrows -> R {
    update(to: step, stepProgress: 0)
    return try action { innerProgress in
      self.update(
        to: step,
        stepProgress: innerProgress.progress,
        customMessage: innerProgress.message
      )
    }
  }

  /// Performs a step with a nested task progress tracker if a condition holds. Returns the result
  /// of the step if it is run.
  public func perform<InnerStep: TaskStep, R>(
    _ step: Step,
    if condition: Bool,
    action: (@escaping (TaskProgress<InnerStep>) -> Void) throws -> R
  ) rethrows -> R? {
    guard condition else {
      return nil
    }

    update(to: step, stepProgress: 0)
    return try action { innerProgress in
      self.update(
        to: step,
        stepProgress: innerProgress.progress,
        customMessage: innerProgress.message
      )
    }
  }
}
