/// Similar idea to SwiftUI bindings, but for arrays. Allows prolonged mutable access to an array.
/// Made it a class so that you're not forced to unnecessarily always store the binding as a `var`
/// just cause you want to assign to it. That would be unnecessary because there's no actual mutation
/// happening to the binding and by nature it's meant to be an opaque two way binding.
public class ArrayBinding<Element> {
  public let getElement: (_ index: Int) -> Element
  public let setElement: (_ index: Int, _ value: Element) -> Void

  public init(get getElement: @escaping (Int) -> Element, set setElement: @escaping (Int, Element) -> Void) {
    self.getElement = getElement
    self.setElement = setElement
  }

  public subscript(_ index: Int) -> Element {
    get {
      getElement(index)
    }
    set {
      setElement(index, newValue)
    }
  }

  public func swapAt(_ firstIndex: Int, _ secondIndex: Int) {
    let first = self[firstIndex]
    let second = self[secondIndex]
    self[firstIndex] = second
    self[secondIndex] = first
  }
}
