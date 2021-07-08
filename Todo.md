# TODO

## UI

- [x] Change ping message to 'Server Offline' instead of pinging when server has responded to ping and is offline
- [x] Reimplement server list editing UI
- [ ] Create settings screen on cmd+,
- [ ] Make flexible way to add settings UI elements
- [ ] proper error messages when joining server
- [ ] direct connect

## Settings

- [ ] Account switching
- [ ] Render distance setting
- [ ] Keymapping
- [ ] Mouse sensitivity
- [ ] Resource pack chooser

## Clean up

- [ ] Move texture loading stuff to DeltaCore
- [ ] DeltaClient probably only needs StorageManager and ConfigManager


# EditableList

init(
  items: Binding<[Item]>,
  selected: Binding<Int?>,
  row: (Item, Bool, (Action) -> Void) -> Row,
  itemEditor: Editor.Type)

enum Action {
  case edit
  case delete
  case moveUp
  case moveDown
  case select
}