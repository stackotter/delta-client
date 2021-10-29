import Foundation

public struct RecipeBookDataPacket: ServerboundPacket {
  public static let id: Int = 0x1e
  
  public var data: RecipeBookData
  
  public enum RecipeBookData {
    case displayedRecipe(recipeId: Identifier)
    case recipeBookStates(state: RecipeBookState)
  }
  
  public struct RecipeBookState {
    public var craftingRecipeBookOpen: Bool
    public var craftingRecipeFilterActive: Bool
    public var smeltingRecipeBookOpen: Bool
    public var smeltingRecipeFilterActive: Bool
    public var blastingRecipeBookOpen: Bool
    public var blastingRecipeFilterActive: Bool
    public var smokingRecipeBookOpen: Bool
    public var smokingRecipeFilterActive: Bool
  }
  
  public func writePayload(to writer: inout PacketWriter) {
    switch data {
      case let .displayedRecipe(recipeId: recipeId):
        writer.writeVarInt(0) // displayed recipes
        writer.writeIdentifier(recipeId)
      case let .recipeBookStates(state: state):
        writer.writeVarInt(1) // recipe book states
        writer.writeBool(state.craftingRecipeBookOpen)
        writer.writeBool(state.craftingRecipeFilterActive)
        writer.writeBool(state.smeltingRecipeBookOpen)
        writer.writeBool(state.smeltingRecipeFilterActive)
        writer.writeBool(state.blastingRecipeBookOpen)
        writer.writeBool(state.blastingRecipeFilterActive)
        writer.writeBool(state.smokingRecipeBookOpen)
        writer.writeBool(state.smokingRecipeFilterActive)
    }
  }
}
