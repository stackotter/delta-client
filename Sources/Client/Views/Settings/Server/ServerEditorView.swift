import SwiftUI
import DeltaCore

struct ServerEditorView: EditorView {
  @State var descriptor: ServerDescriptor
  @State var errorMessage: String?
  
  var completionHandler: (ServerDescriptor) -> Void
  var cancelationHandler: (() -> Void)?
  
  @State var isAddressValid = false
  /// True if this is editing an existing server.
  let isEditor: Bool
  
  init(_ item: ServerDescriptor?, completion: @escaping (ServerDescriptor) -> Void, cancelation: (() -> Void)?) {
    completionHandler = completion
    cancelationHandler = cancelation
    
    isEditor = item != nil
    _descriptor = State(initialValue: item ?? ServerDescriptor(name: "", host: "", port: nil))
  }
  
  private func verify() -> Bool {
    if !isAddressValid {
      errorMessage = "Invalid IP"
    } else {
      return true
    }
    return false
  }
  
  var body: some View {
    VStack(spacing: 16) {
      HStack(alignment: .bottom) {
        Text("Add server")
          .font(Font.custom(.worksans, size: 25))
          .foregroundColor(.white)
        Spacer()
      }
      .frame(maxWidth: .infinity)
      
        StyledTextField(title: "Name", text: $descriptor.name)
      AddressField("Address", host: $descriptor.host, port: $descriptor.port, isValid: $isAddressValid)
      
      HStack(spacing: 16) {
        StyledButton(
          action: { cancelationHandler?() },
          height: 35,
          text: "Cancel"
        )
        StyledButton(
          action: { if verify() { completionHandler(descriptor) } },
          height: 35,
          text: "Save"
        )
      }
      
      if let errorMessage = errorMessage {
        HStack {
          Text(errorMessage)
            .font(Font.custom(.worksans, size: 11))
            .foregroundColor(.red)
          Spacer()
        }
        .frame(maxWidth: .infinity)
      }
    }
    .padding(.top, 16)
    .frame(width: 400)
  }
}
