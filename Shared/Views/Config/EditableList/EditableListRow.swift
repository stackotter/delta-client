//
//  EditableListRow.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 7/7/21.
//

import SwiftUI

struct EditableListRow<Content: View>: View {
  /// The number of items in the list this is in
  let count: Int
  let index: Int
  let content: () -> Content
  
  let handler: (Int, EditListAction) -> Void
  
  init(
    at index: Int,
    outOf count: Int,
    @ViewBuilder content: @escaping () -> Content,
    handler: @escaping (Int, EditListAction) -> Void
  ) {
    self.index = index
    self.count = count
    self.content = content
    self.handler = handler
  }
  
  var body: some View {
    HStack {
      VStack {
        IconButton("chevron.up", isDisabled: index == 0) {
          handler(index, .moveUp)
        }
        IconButton("chevron.down", isDisabled: index == count - 1) {
          handler(index, .moveDown)
        }
      }
      
      VStack(alignment: .leading) {
        content()
      }
      
      Spacer()
      
      HStack {
        IconButton("square.and.pencil") {
          handler(index, .edit)
        }
        IconButton("xmark") {
          handler(index, .delete)
        }
      }
    }
  }
}
