import FirebladeECS

@dynamicMemberLookup
public final class GUIStateStorage: SingleComponent {
  public var inner = GUIState()

  public init() {}

  subscript<T>(dynamicMember member: WritableKeyPath<GUIState, T>) -> T {
    get {
      inner[keyPath: member]
    }
    set {
      inner[keyPath: member] = newValue
    }
  }
}
