import SwiftUI

enum EditableListState {
  case list
  case addItem
  case editItem(Int)
}

enum EditableListAction {
  case delete
  case edit
  case moveUp
  case moveDown
  case select
}

struct EditableList<Row: View, ItemEditor: EditorView>: View {
  @ObservedObject var state = StateWrapper<EditableListState>(initial: .list)

  @Binding var items: [ItemEditor.Item]
  @Binding var selected: Int?

  let itemEditor: ItemEditor.Type
  let row: (
    _ item: ItemEditor.Item,
    _ selected: Bool,
    _ isFirst: Bool,
    _ isLast: Bool,
    _ handler: @escaping (EditableListAction) -> Void
  ) -> Row

  /// If defined, callback is triggered on save.
  let save: (() -> Void)?
  /// If defined, callback is triggered on edit cancel.
  let cancel: (() -> Void)?
  /// If defined, callback is triggered on item add.
  let add: (() -> Void)?
  /// If defined, callback is triggered on item edit.
  let edit: (() -> Void)?

  /// Message to display when the list is empty.
  let emptyMessage: String
  
  /// List title
  let title: String

  init(
    _ items: Binding<[ItemEditor.Item]>,
    selected: Binding<Int?> = Binding<Int?>(get: { nil }, set: { _ in }),
    itemEditor: ItemEditor.Type,
    @ViewBuilder row: @escaping (
      _ item: ItemEditor.Item,
      _ selected: Bool,
      _ isFirst: Bool,
      _ isLast: Bool,
      _ handler: @escaping (EditableListAction) -> Void
    ) -> Row,
    saveAction: (() -> Void)?,
    cancelAction: (() -> Void)?,
    addAction: (() -> Void)? = nil,
    editAction: (() -> Void)? = nil,
    emptyMessage: String = "No items",
    title: String
  ) {
    self._items = items
    self._selected = selected
    self.itemEditor = itemEditor
    self.row = row
    self.emptyMessage = emptyMessage
    self.title = title
    save = saveAction
    cancel = cancelAction
    edit = editAction
    add = addAction
  }

  func handleItemAction(_ index: Int, _ action: EditableListAction) {
    switch action {
      case .delete:
        if selected == index {
          if items.count == 1 {
            selected = nil
          } else {
            selected = 0
          }
        } else if let selectedIndex = selected, selectedIndex > index {
          selected = selectedIndex - 1
        }
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
      case .select:
        selected = index
    }
  }

  var body: some View {
    Group {
      switch state.current {
        case .list:
          VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .bottom) {
              Text(title)
                .font(Font.custom(.worksans, size: 25))
                .foregroundColor(.white)
              Spacer()
              StyledButton(
                action: {
                  if let add = add {
                    add()
                  } else {
                    state.update(to: .addItem)
                  }
                },
                icon: Image(systemName: "square.and.pencil"),
                text: "Edit"
              )
                .frame(width: 120)
            }
            .frame(maxWidth: .infinity)
            
            ScrollView(showsIndicators: true) {
              ForEach(items.indices, id: \.self) { index in
                VStack(alignment: .leading) {
                  let isFirst = index == 0
                  let isLast = index == items.count - 1
                  row(items[index], selected == index, isFirst, isLast, { action in
                    handleItemAction(index, action)
                  })

                  if index == items.count - 1 {
                    Divider()
                  }
                }
              }
            }

            VStack {
              Button("Add") {
                state.update(to: .addItem)
              }
              .buttonStyle(SecondaryButtonStyle())

              if save != nil || cancel != nil {
                HStack {
                  if let cancel = cancel {
                    Button("Cancel", action: cancel)
                      .buttonStyle(SecondaryButtonStyle())
                  }
                  if let save = save {
                    Button("Save", action: save)
                      .buttonStyle(PrimaryButtonStyle())
                  }
                }
              }
            }
              .frame(maxWidth: .infinity, maxHeight: 400)
          }
            .frame(maxWidth: .infinity)
        case .addItem:
          VStack(spacing: 0) {
            itemEditor.init(nil, completion: { newItem in
              items.append(newItem)
              selected = items.count - 1
              state.update(to: .list)
            }, cancelation: {
              state.update(to: .list)
            })
          }
          
        case let .editItem(index):
          VStack(spacing: 0) {
            itemEditor.init(items[index], completion: { editedItem in
              items[index] = editedItem
              state.update(to: .list)
            }, cancelation: {
              state.update(to: .list)
            })
          }
      }
    }
    .frame(width: 400)
  }
}
