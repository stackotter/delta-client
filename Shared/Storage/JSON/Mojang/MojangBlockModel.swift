//
//  MojangBlockModel.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 3/7/21.
//

import Foundation
import DeltaCore

/// The structure of a block model as read from a resource pack.
public struct MojangBlockModel: Codable {
  /// The identifier of the parent of this block model.
  public var parent: Identifier?
  /// Whether to use ambient occlusion or not.
  public var ambientOcclusion: Bool?
  /// Transformations to use when displaying this block in certain situations.
  public var display: MojangBlockModelDisplay?
  /// Texture variables used in this block model.
  public var textures: [String: String]?
  /// The elements that make up this block model.
  public var elements: [MojangBlockModelElement]?
  
  enum CodingKeys: String, CodingKey {
    case parent
    case ambientOcclusion = "ambientocclusion"
    case display
    case textures
    case elements
  }
}
