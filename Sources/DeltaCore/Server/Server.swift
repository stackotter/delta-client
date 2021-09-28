import Foundation

/// A type representing everything the client knows about a server.
public struct Server {
  /// Number of worlds on the server.
  public private(set) var worldCount = 0
  /// An array containing the identifiers for all of the server's worlds.
  public private(set) var worldNames: [Identifier] = []
  
  /// The current world.
  public var world: World
  /// The currently connected player.
  public var player: Player
  
  /// A structure holding information about all of the server's dimensions.
  public private(set) var dimensionCodec = NBT.Compound() // TODO: create actual dimension codec struct
  
  /// The maximum number of players that can join the server.
  public private(set) var maxPlayers: UInt8 = 0
  /// The render distance of the server.
  public private(set) var viewDistance = 0
  /// Whether the server sends reduced debug info or not.
  public private(set) var useReducedDebugInfo = false
  /// Whether the client should show the respawn screen on death.
  public private(set) var enableRespawnScreen = false
  
  /// The list of all players on the server.
  public var tabList = TabList()
  /// Registry holding all of the server's recipes.
  public private(set) var recipeRegistry = RecipeRegistry()
  
  /// The difficulty of the server.
  public private(set) var difficulty = Difficulty.normal
  /// Whether the server is hardcode or not.
  public private(set) var isHardcore = false
  /// Whether the server's difficulty is locked for the player or not.
  public private(set) var isDifficultyLocked = false
  
  /// Create a new server from a `JoinGamePacket`.
  public init(from packet: JoinGamePacket, for client: Client) {
    worldCount = packet.worldCount
    worldNames = packet.worldNames
    dimensionCodec = packet.dimensionCodec
    maxPlayers = packet.maxPlayers
    viewDistance = packet.viewDistance
    useReducedDebugInfo = packet.reducedDebugInfo
    enableRespawnScreen = packet.enableRespawnScreen
    isHardcore = packet.isHardcore
    
    player = Player(from: packet)
    world = World(from: packet, blockRegistry: client.registry.blockRegistry, batching: client.batchWorldUpdates)
  }
  
  /// Update the server's difficulty with a `ServerDifficultyPacket`.
  public mutating func update(with packet: ServerDifficultyPacket) {
    difficulty = packet.difficulty
    isDifficultyLocked = packet.isLocked
  }
  
  /// Update the server's recipe registry
  public mutating func updateRecipeRegistry(to newRegistry: RecipeRegistry) {
    recipeRegistry = newRegistry
  }
}
