//
//  ServerEditorView.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 8/7/21.
//

import SwiftUI
import DeltaCore

struct ServerEditorView: EditorView {
  @State var descriptor: ServerDescriptor
  @State var errorMessage: String?
  
  var completionHandler: (ServerDescriptor) -> Void
  var cancelationHandler: (() -> Void)?
  
  @State var isIpValid = false
  
  init(_ item: ServerDescriptor?, completion: @escaping (ServerDescriptor) -> Void, cancelation: (() -> Void)?) {
    completionHandler = completion
    cancelationHandler = cancelation
    
    _descriptor = State(initialValue: item ?? ServerDescriptor(name: "", host: "", port: nil))
  }
  
  private func verify() -> Bool {
    if !isIpValid {
      errorMessage = "Invalid IP"
    } else {
      return true
    }
    return false
  }
  
  var body: some View {
    VStack {
      TextField("Server name", text: $descriptor.name)
      IPField("Server ip", host: $descriptor.host, port: $descriptor.port, isValid: $isIpValid)
      
      if let message = errorMessage {
        Text(message)
          .bold()
      }
      
      HStack {
        Button("Save") {
          if verify() { completionHandler(descriptor) }
        }
        if let cancel = cancelationHandler {
          Button("Cancel", action: cancel)
            .buttonStyle(BorderlessButtonStyle())
        }
      }
    }
    .frame(width: 200)
  }
}
