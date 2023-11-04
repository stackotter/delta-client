import Foundation

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
      guard step != currentStep else {
        break
      }
      guard !skippedSteps.contains(step) else {
        continue
      }
      progress += step.relativeDuration
    }

    progress += currentStep.relativeDuration * stepProgress
    return progress / totalTaskDuration
  }

  /// The current step. `nil` when initially created.
  public private(set) var currentStep: Step?
  /// The progress of the current step from 0 to 1.
  public private(set) var stepProgress: Double = 0
  /// Steps that have been skipped (which get excluded from the total for a more accurate
  /// indication of progress).
  public private(set) var skippedSteps: [Step] = []
  /// A custom message overriding the message of the current step. Useful when
  /// nesting tasks.
  public private(set) var customMessage: String?

  /// A handler to call whenever the progress changes.
  private var changeHandler: ((TaskProgress<Step>) -> Void)?

  /// A handle to the observation of a step's nested `Progress`. Required to keep
  /// the handle alive until the step completes.
  private var observation: NSKeyValueObservation?

  /// The total combined duration of all steps. There is no unit, it is just the sum
  /// of relative durations. Excludes ``TaskProgress/skippedSteps``.
  private var totalTaskDuration: Double {
    Step.allCases.map { step in
      if skippedSteps.contains(step) {
        return 0
      } else {
        return step.relativeDuration
      }
    }.reduce(into: 0, { $0 += $1 })
  }

  /// Creates a new task progress tracker. Initially has no current step.
  public init() {}

  /// Resets the task progress back to the start.
  public func reset() {
    currentStep = nil
    stepProgress = 0
    customMessage = nil
    skippedSteps = []
  }

  /// Adds a step handler to the progress. The handler gets run whenever the current
  /// step changes (not triggered if the step progress changes while the step remains
  /// the same). Can be called multiple times to create a chain of handlers.
  @discardableResult
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
    ThreadUtil.runInMain {
      currentStep = step
      self.stepProgress = stepProgress
      self.customMessage = customMessage
      changeHandler?(self)
    }
  }

  /// Marks a step as skipped. It's not required to mark skipped steps
  /// as skipped, but it allows for progress to be estimated more accurately.
  public func skip(_ step: Step) {
    ThreadUtil.runInMain {
      skippedSteps.append(step)
      changeHandler?(self)
    }
  }

  /// Performs a step and returns its result.
  public func perform<R>(_ step: Step, action: () throws -> R) rethrows -> R {
    update(to: step, stepProgress: 0)
    return try action()
  }

  /// Performs a step and returns its result. Skips the step if the
  /// given condition doesn't hold.
  public func perform<R>(
    _ step: Step,
    if condition: Bool,
    action: () throws -> R
  ) rethrows -> R? {
    guard condition else {
      skip(step)
      return nil
    }

    update(to: step, stepProgress: 0)
    return try action()
  }

  /// Performs a step and runs a handler if it fails. Returns the result
  /// of the step if it succeeds.
  public func perform<R>(
    _ step: Step,
    action: () throws -> R,
    handleError: (any Error) -> Void
  ) -> R? {
    update(to: step, stepProgress: 0)
    do {
      return try action()
    } catch {
      handleError(error)
      return nil
    }
  }

  /// Performs a step and runs a handler if it fails. Returns the result
  /// of the step if it succeeds. Skips the step if the given condition
  /// doesn't hold.
  public func perform<R>(
    _ step: Step,
    if condition: Bool,
    action: () throws -> R,
    handleError: (any Error) -> Void
  ) -> R? {
    guard condition else {
      skip(step)
      return nil
    }

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
    action: (TaskProgress<InnerStep>) throws -> R
  ) rethrows -> R {
    update(to: step, stepProgress: 0)
    let innerProgress = TaskProgress<InnerStep>()
    innerProgress.onChange { innerProgress in
      self.update(
        to: step,
        stepProgress: innerProgress.progress,
        customMessage: innerProgress.message
      )
    }
    return try action(innerProgress)
  }

  /// Performs a step with a nested task progress tracker. Skips the step
  /// if the condition isn't met.
  public func perform<InnerStep: TaskStep, R>(
    _ step: Step,
    if condition: Bool,
    action: (TaskProgress<InnerStep>) throws -> R
  ) rethrows -> R? {
    guard condition else {
      skip(step)
      return nil
    }

    update(to: step, stepProgress: 0)
    let innerProgress = TaskProgress<InnerStep>()
    innerProgress.onChange { innerProgress in
      self.update(
        to: step,
        stepProgress: innerProgress.progress,
        customMessage: innerProgress.message
      )
    }
    return try action(innerProgress)
  }

  // TODO: This feels a bit janky and less intuitive than the other methods. Perhaps a more descriptive
  //   method name would help.
  /// Performs a step with a nested progress tracker. The step is given a way to register
  /// a nested progress object.
  public func perform<R>(
    _ step: Step,
    action: ((Progress) -> Void) async throws -> R
  ) async rethrows -> R {
    update(to: step, stepProgress: 0)

    let result = try await action() { progress in
      observation = progress.observe(\.fractionCompleted, options: [.new]) { progress, change in
        self.update(to: step, stepProgress: change.newValue!)
      }
    }
    observation = nil

    return result
  }

  /// Performs a step with a nested progress tracker. The step is given a
  /// way to register a nested progress object. Skips the step if the condition isn't met.
  public func perform<R>(
    _ step: Step,
    if condition: Bool,
    action: ((Progress) -> Void) async throws -> R
  ) async rethrows -> R? {
    guard condition else {
      skip(step)
      return nil
    }

    update(to: step, stepProgress: 0)

    let result = try await action() { progress in
      observation = progress.observe(\.fractionCompleted, options: [.new]) { progress, change in
        self.update(to: step, stepProgress: change.newValue!)
      }
    }
    observation = nil

    return result
  }
}
