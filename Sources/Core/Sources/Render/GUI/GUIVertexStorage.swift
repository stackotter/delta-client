/// Vertices are stored in tuples as an optimisation.
typealias GUIQuadVertices = (GUIVertex, GUIVertex, GUIVertex, GUIVertex)

/// Specialized storage for GUI vertices that can work with two different storage formats (with
/// identical memory layouts, but different types). This is useful because using tuples that group
/// vertices into groups of four is faster when generating the vertices for lots of quads, but some
/// code still generates vertices in the `flatArray` format.
enum GUIVertexStorage {
  case tuples([GUIQuadVertices])
  // TODO: Refactor block mesh generation to generate vertices in tuples so that this type can be
  // removed. Doing so should hopefully also improve block mesh generation performance.
  case flatArray([GUIVertex])
}

extension GUIVertexStorage {
  static let empty = GUIVertexStorage.tuples([])

  var count: Int {
    switch self {
      case .tuples(let tuples):
        return tuples.count * 4
      case .flatArray(let array):
        return array.count
    }
  }

  @discardableResult
  mutating func withUnsafeMutableRawPointer<Return>(_ action: (UnsafeMutableRawPointer) -> Return) -> Return {
    switch self {
      case .tuples(var tuples):
        return action(&tuples)
      case .flatArray(var array):
        return action(&array)
    }
  }

  mutating func mutateEach(_ action: (inout GUIVertex) -> Void) {
    switch self {
      case .tuples(var tuples):
        self = .tuples([]) // Avoid copy caused by CoW by making `tuples` uniquely referenced
        for i in 0..<tuples.count {
          action(&tuples[i].0)
          action(&tuples[i].1)
          action(&tuples[i].2)
          action(&tuples[i].3)
        }
        self = .tuples(tuples)
      case .flatArray(var array):
        self = .flatArray([]) // Avoid copy caused by CoW by making `array` uniquely referenced
        for i in 0..<array.count {
          action(&array[i])
        }
        self = .flatArray(array)
    }
  }

  mutating func append(contentsOf other: GUIVertexStorage) {
    switch self {
      case .tuples(var tuples):
        self = .tuples([])
        tuples.append(contentsOf: other.toTuples())
        self = .tuples(tuples)
      case .flatArray(var array):
        self = .flatArray([])
        array.append(contentsOf: other.toFlatArray())
        self = .flatArray(array)
    }
  }

  private func toTuples() -> [GUIQuadVertices] {
    switch self {
      case .tuples(let tuples):
        return tuples
      case .flatArray(let array):
        // This should never trigger becaues if the length of this array is not a multiple of 4 it
        // would mess up the rendering code anyway (which assumes quads made up of 4 vertices each).
        precondition(
          array.count % 4 == 0,
          "Flat array of GUI vertices must have a length which is a multiple of 4"
        )

        return array.withUnsafeBufferPointer { pointer in
          return pointer.withMemoryRebound(to: GUIQuadVertices.self) { buffer in
            return Array(buffer)
          }
        }
    }
  }

  private func toFlatArray() -> [GUIVertex] {
    switch self {
      case .tuples(let tuples):
        return tuples.withUnsafeBufferPointer { pointer in
          return pointer.withMemoryRebound(to: GUIVertex.self) { buffer in
            return Array(buffer)
          }
        }
      case .flatArray(let array):
        return array
    }
  }
}
