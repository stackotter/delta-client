//
//  MojangBlockModelElement.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 3/7/21.
//

import Foundation

/// A block model element as read from a Mojang formatted block model file.
public struct MojangBlockModelElement: Codable {
  /// The starting point of the element.
  public var from: [Double]
  /// The finishing point of the element.
  public var to: [Double]
  /// The rotation of the element.
  public var rotation: MojangBlockModelElementRotation?
  /// Whether to render shadows or not, if nil assume true.
  public var shade: Bool?
  /// The present faces of the element.
  public var faces: [MojangBlockModelFaceName: MojangBlockModelFace]
}
