//
//  GitHubArtifactsAPIResponse.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 28/9/21.
//

import Foundation

struct GitHubArtifactsAPIResponse: Codable {
  var artifacts: [Artifact]
  
  struct Artifact: Codable {
    var id: Int
    var expired: Bool
  }
}
