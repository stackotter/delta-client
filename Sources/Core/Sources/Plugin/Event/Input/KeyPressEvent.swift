public struct KeyPressEvent: Event {
  public var key: Key?
  public var input: Input?
  public var characters: [Character]

  public init(key: Key?, input: Input?, characters: [Character]) {
    self.key = key
    self.characters = characters
    self.input = input
  }
}
