/// A renderable model of an item.
public enum ItemModel {
  case layered(textureIndices: [ItemModelTexture], transforms: ModelDisplayTransforms)
  case block(id: Int)
  case entity(Identifier, transforms: ModelDisplayTransforms)
  case empty
}
