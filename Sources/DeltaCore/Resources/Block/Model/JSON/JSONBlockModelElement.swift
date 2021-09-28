//
//  JSONBlockModelElement.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 3/7/21.
//

import Foundation

/// A block model element as read from a Mojang formatted block model file.
public struct JSONBlockModelElement: Codable {
  /// The starting point of the element.
  public var from: [Double]
  /// The finishing point of the element.
  public var to: [Double]
  /// The rotation of the element.
  public var rotation: JSONBlockModelElementRotation?
  /// Whether to render shadows or not, if nil assume true.
  public var shade: Bool?
  /// The present faces of the element. The keys are face direction and should be one of;
  /// `down`, `up`, `north`, `south`, `west` or `east`
  public var faces: [String: JSONBlockModelFace]
}
