import Foundation

struct GUITextInput: GUIElement {
  var content: String
  var width: Int
  var cursorIndex: String.Index

  func meshes(context: GUIContext) throws -> [GUIElementMesh] {
    // Background
    let background = GUIRectangle(
      size: [width, 11],
      color: [0, 0, 0, 0.5]
    ).meshes(context: context)

    // Message
    let messageBeforeCursor = String(content.prefix(upTo: cursorIndex))
    let messageAfterCursor = String(content.suffix(from: cursorIndex))
    var messageMeshBeforeCursor = try messageBeforeCursor.meshes(context: context)
    var messageMeshAfterCursor = try messageAfterCursor.meshes(context: context)

    if messageMeshBeforeCursor.size().x != 0 {
      messageMeshBeforeCursor.translate(amount: [2, 2])
      messageMeshAfterCursor.translate(amount: [3 + messageMeshBeforeCursor.size().x, 2])
    } else {
      messageMeshBeforeCursor.translate(amount: [0, 2])
      messageMeshAfterCursor.translate(amount: [2, 2])
    }
    var cursor: [GUIElementMesh] = []
    // When at the end of the message, use an underscore cursor. Otherwise, use a vertical bar cursor
    if Int(CFAbsoluteTimeGetCurrent() * 10/3) % 2 == 1 {
      if messageMeshAfterCursor.size().x == 0 {
        cursor = try "_".meshes(context: context)
        let messageWidth = messageMeshBeforeCursor.size().x + messageMeshAfterCursor.size().x
        var xOffset: Int
        if messageWidth != 0 {
          xOffset = messageWidth + 4
        } else {
          xOffset = 2
        } 
        cursor.translate(amount: [xOffset, 2])
      } else {
        let cursorWidth = 1
        let cursorHeight = 10
        cursor = GUIRectangle(
          size: [cursorWidth, cursorHeight],
          color: [1, 1, 1, 1]
        ).meshes(context: context)
        var xOffset: Int
        if messageMeshBeforeCursor.size().x == 0 {
          xOffset = messageMeshBeforeCursor.size().x + 2
        } else {
          xOffset = messageMeshBeforeCursor.size().x + 3
        } 
        cursor.translate(amount: [xOffset, 1])
      }
    }
    return background + messageMeshBeforeCursor + messageMeshAfterCursor + cursor
  }
}
