import SwiftUI

struct FatalErrorView: View {
  let message: String
  
  var body: some View {
    Text(message)
      .frame(width: 400)
      .navigationTitle("Fatal Error")
  }
}
