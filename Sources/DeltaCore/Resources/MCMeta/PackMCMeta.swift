//
//  PackMCMeta.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 16/7/21.
//

import Foundation

extension ResourcePack {
  /// The format of a pack.mcmeta file in a mojang resource pack.
  public struct PackMCMeta: Decodable {
    var metadata: Metadata
    var languages: [String: Language]?
    
    private enum CodingKeys: String, CodingKey {
      case metadata = "pack"
      case languages = "language"
    }
  }
}

// MARK: Metadata

extension ResourcePack.PackMCMeta {
  public struct Metadata: Decodable {
    public var formatVersion: Int
    
    private enum CodingKeys: String, CodingKey {
      case formatVersion = "pack_format"
    }
  }
}

// MARK: Language Metadata

extension ResourcePack.PackMCMeta {
  public struct Language: Decodable {
    public var name: String
    public var region: String
    public var bidirectional: Bool
  }
}
