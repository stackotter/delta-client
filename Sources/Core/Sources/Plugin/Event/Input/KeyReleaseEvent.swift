public struct KeyReleaseEvent: Event {
  public var key: Key?
  public var input: Input?

  public init(key: Key?, input: Input?) {
    self.key = key
    self.input = input
  }
}
