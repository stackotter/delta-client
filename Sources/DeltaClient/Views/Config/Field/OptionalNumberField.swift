//
//  OptionalNumberField.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 8/7/21.
//

import SwiftUI
import Combine

struct OptionalNumberField<Number: FixedWidthInteger>: View {
  let title: String
  
  @State private var string: String
  @Binding private var number: Number?
  
  @Binding private var isValid: Bool
  
  init(_ title: String, number: Binding<Number?>, isValid: Binding<Bool>) {
    self.title = title
    
    _number = number
    _string = State(initialValue: number.wrappedValue?.description ?? "")
    _isValid = isValid
  }
  
  var body: some View {
    TextField(title, text: $string)
      .onReceive(Just(string)) { newValue in
        if newValue == "" {
          number = nil
          isValid = false
        }
        
        if let number = Number(newValue) {
          self.number = number
          isValid = true
        } else {
          isValid = false
        }
      }
  }
}
