//
//  Logging.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 20/6/21.
//

import Foundation
import DeltaLogger
import Logging

var log = Logger(label: "DeltaClient") { label in
  DeltaLogHandler(label: label)
}
