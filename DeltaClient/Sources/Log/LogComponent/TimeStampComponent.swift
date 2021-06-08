//
//  TimeStampComponent.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 7/6/21.
//

import Foundation
import Puppy

struct TimeStampComponent: LogComponent {
  var date: Date
  
  private static var dateFormatter = makeDefaultDateFormatter()
  
  private static func makeDefaultDateFormatter() -> DateFormatter {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd-MM-yyyy HH:mm:ss.SSSS"
    return dateFormatter
  }
  
  func toString() -> String {
    return TimeStampComponent.dateFormatter.string(from: date)
  }
}
