public protocol TaskStep: CaseIterable, Equatable {
  var message: String { get }
  var relativeDuration: Double { get }
}
