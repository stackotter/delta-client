extension World.Event {
  public struct TimeUpdate: Event {
    public let worldAge: Int
    public let timeOfDay: Int
  }
}
