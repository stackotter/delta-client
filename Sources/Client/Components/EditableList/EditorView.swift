import SwiftUI

protocol EditorView: View {
  associatedtype Item
  
  init(_ item: Item?, completion: @escaping (Item) -> Void, cancelation: (() -> Void)?)
}
