//
//  GitHubReleasesAPIResponse.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 28/9/21.
//

import Foundation

struct GitHubReleasesAPIResponse: Codable {
  var tagName: String
  var assets: [Asset]
  
  struct Asset: Codable {
    var browserDownloadUrl: String
  }
}
