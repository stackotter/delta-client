//
//  VersionManifest.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 3/7/21.
//

import Foundation

struct VersionManifest: Codable {
  var assetIndex: AssetIndex
  var assets: String
  var downloads: Downloads
  var id: String
  var releaseTime: Date
  var time: Date
  var type: VersionsManifest.VersionType
  
  struct AssetIndex: Codable {
    var id: String
    var sha1: String
    var size: Int
    var totalSize: Int
    var url: URL
  }
  
  struct Downloads: Codable {
    var client: Download
    var clientMappings: Download
    var server: Download
    var serverMappings: Download
    
    enum CodingKeys: String, CodingKey {
      case client
      case clientMappings = "client_mappings"
      case server
      case serverMappings = "server_mappings"
    }
  }
  
  struct Download: Codable {
    var sha1: String
    var size: Int
    var url: URL
  }
}
