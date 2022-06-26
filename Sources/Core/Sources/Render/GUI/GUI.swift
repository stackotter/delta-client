import Metal
import simd

struct GUI {
  var elements: [GUIElement] = []
  var font: Font

  init(client: Client) {
    font = client.resourcePack.vanillaResources.fontPalette.defaultFont
    elements = [
      GUIElement("center", .center),
      GUIElement("top left", .position(0, 0)),
      GUIElement("top right", .top(0), .right(0)),
      GUIElement("bottom right", .bottom(0), .right(0)),
      GUIElement("bottom left", .bottom(0), .left(0))
    ]
  }

  func meshes(device: MTLDevice, scale: Float, effectiveDrawableSize: SIMD2<Float>) throws -> [GUIElementMesh] {
    var meshes: [GUIElementMesh] = []
    for element in elements {
      var mesh: GUIElementMesh
      switch element.content {
        case .text(let text):
          mesh = try GUIElementMesh(text: text, font: font, device: device)
      }

      let x: Float
      switch element.constraints.horizontal {
        case .left(let distance):
          x = Float(distance)
        case .center:
          x = (effectiveDrawableSize.x - mesh.width) / 2
        case .right(let distance):
          x = effectiveDrawableSize.x - mesh.width - Float(distance)
      }

      let y: Float
      switch element.constraints.vertical {
        case .top(let distance):
          y = Float(distance)
        case .center:
          y = (effectiveDrawableSize.y - mesh.height) / 2
        case .bottom(let distance):
          y = effectiveDrawableSize.y - mesh.height - Float(distance)
      }

      mesh.position = [x, y]

      meshes.append(mesh)
    }

    return meshes
  }
}
