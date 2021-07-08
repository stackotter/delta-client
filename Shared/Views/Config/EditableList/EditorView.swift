//
//  EditorView.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 7/7/21.
//

import SwiftUI

protocol EditorView: View {
  associatedtype Item
  
  init(_ item: Item?, completion: @escaping (Item) -> Void, cancelation: @escaping () -> Void)
}
