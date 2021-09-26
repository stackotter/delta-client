//
//  EmailField.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 8/7/21.
//

import SwiftUI
import Combine

struct EmailField: View {
  static private let regex = try! NSRegularExpression(pattern: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}")
  
  private let title: String
  
  @Binding private var email: String
  @Binding private var isValid: Bool
  
  init(
    _ title: String,
    email: Binding<String>,
    isValid: Binding<Bool> = Binding<Bool>(get: { false }, set: { _ in })
  ) {
    self.title = title
    _email = email
    _isValid = isValid
  }
  
  private func validate(_ email: String) {
    let range = NSRange(location: 0, length: email.utf16.count)
    isValid = Self.regex.firstMatch(in: email, options: [], range: range) != nil
  }
  
  var body: some View {
    TextField(title, text: $email)
      .onReceive(Just(email), perform: validate)
      .onAppear {
        validate(email)
      }
  }
}
