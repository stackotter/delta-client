import FirebladeECS

/// A component storing an entity's camera properties.
public class EntityCamera: Component {
  /// A camera perspective.
  public enum Perspective: Int, Codable, CaseIterable {
    /// Rendered as if looking from the entity's eyes.
    case firstPerson
    /// Rendered from behind the entity's head, looking at the back of the entity's head.
    case thirdPersonRear
    /// Rendered in front of the entity's head, looking at the entity's face.
    case thirdPersonFront
  }
  
  /// The current perspective.
  public var perspective: Perspective
  
  /// Creates an entity's camera.
  /// - Parameter perspective: Defaults to ``Perspective-swift.enum/firstPerson``.
  public init(perspective: Perspective = .thirdPersonRear) {
    self.perspective = perspective
  }
  
  /// Changes to the next perspective.
  public func cyclePerspective() {
    let index = (perspective.rawValue + 1) % Perspective.allCases.count
    perspective = Perspective.allCases[index]
  }
}

