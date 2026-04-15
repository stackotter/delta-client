/// A block or an entity. Starting to run out of ambiguous nouns!
public enum Thing {
  case block(position: BlockPosition)
  case entity(id: Int)
}
