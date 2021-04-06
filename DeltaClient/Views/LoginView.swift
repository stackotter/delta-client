//
//  LoginView.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 7/4/21.
//

import SwiftUI

struct LoginView: View {
  var callback: (_ email: String, _ password: String) -> ()
  
  @State var email: String = ""
  @State var password: String = ""
  
  var body: some View {
    VStack(alignment: .center, spacing: 16) {
      TextField("email", text: $email)
      SecureField("password", text: $password)
      Button("login") {
        callback(email, password)
      }
    }.frame(width: 300, height: nil, alignment: .center)
  }
}
