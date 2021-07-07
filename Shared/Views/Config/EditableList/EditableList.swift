//
//  EditableList.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 7/7/21.
//

import SwiftUI

enum EditableListState {
  case list
  case addItem
  case editItem(Int)
}

enum EditListAction {
  case delete
  case edit
  case moveUp
  case moveDown
}

struct EditableList<ItemLabel: View, ItemEditor: EditorView>: View {
  @ObservedObject var state = StateWrapper<EditableListState>(initial: .list)
  @State var items: [ItemEditor.Item]
  
  let itemLabel: (ItemEditor.Item) -> ItemLabel
  let itemEditor: ItemEditor.Type
  
  let completionHandler: ([ItemEditor.Item]) -> Void
  let cancelationHandler: () -> Void
  
  init(
    _ items: [ItemEditor.Item],
    itemEditor: ItemEditor.Type,
    @ViewBuilder itemLabel: @escaping (ItemEditor.Item) -> ItemLabel,
    completion: @escaping ([ItemEditor.Item]) -> Void,
    cancelation: @escaping () -> Void
  ) {
    self._items = State(initialValue: items)
    self.itemLabel = itemLabel
    self.itemEditor = itemEditor
    completionHandler = completion
    cancelationHandler = cancelation
  }
  
  func handleItemAction(_ index: Int, _ action: EditListAction) {
    switch action {
      case .delete:
        items.remove(at: index)
      case .edit:
        state.update(to: .editItem(index))
      case .moveUp:
        if index != 0 {
          let item = items.remove(at: index)
          items.insert(item, at: index - 1)
        }
      case .moveDown:
        if index != items.count - 1 {
          let item = items.remove(at: index)
          items.insert(item, at: index + 1)
        }
    }
  }
  
  var body: some View {
    Group {
      switch state.current {
        case .list:
          VStack(alignment: .center, spacing: 16) {
            ScrollView(showsIndicators: true) {
              ForEach(items.indices, id: \.self) { index in
                VStack(alignment: .leading) {
                  Divider()
                  
                  EditableListRow(at: index, outOf: items.count, content: {
                    itemLabel(items[index])
                  }, handler: handleItemAction)
                  
                  if index == items.count - 1 {
                    Divider()
                  }
                }
              }
            }
            
            Button("Add") {
              state.update(to: .addItem)
            }
            
            HStack {
              Button("Save") {
                completionHandler(items)
              }
              Button("Cancel", action: cancelationHandler)
                .buttonStyle(BorderlessButtonStyle())
            }
          }
        case .addItem:
          itemEditor.init(nil, completion: { newItem in
            items.append(newItem)
            state.update(to: .list)
          }, cancelation: {
            state.update(to: .list)
          })
        case let .editItem(index):
          itemEditor.init(items[index], completion: { editedItem in
            items[index] = editedItem
            state.update(to: .list)
          }, cancelation: {
            state.update(to: .list)
          })
      }
    }
    .frame(width: 400)
  }
}
