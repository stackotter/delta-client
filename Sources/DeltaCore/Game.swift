import Foundation
import FirebladeECS

/// Stores all of the game data such as entities, chunks and chat messages.
public struct Game {
  /// The container for the game's entities. Strictly only contains what Minecraft counts as entities.
  public var entities = Nexus()
  /// The scheduler that runs the game's systems every 20th of a second.
  public var tickScheduler = TickScheduler()
  /// The event bus for emitting events.
  public var eventBus = EventBus()
  
  /// The currently connected player.
  public var player = Player()
  /// The world the player is currently connected to.
  public var world = World()
  /// The list of all players in the game.
  public var tabList = TabList()
  /// The names of all worlds in this game
  public var worldNames: [Identifier] = []
  /// A structure holding information about all of the dimensions (sent by server).
  public var dimensions = NBT.Compound() // TODO: create actual dimension struct
  /// Registry containing all recipes in this game (sent by server).
  public var recipeRegistry = RecipeRegistry()
  
  /// The render distance of the server.
  public var maxViewDistance = 0
  /// The maximum number of players that can join the server.
  public var maxPlayers = 0
  
  /// Whether the server sends reduced debug info or not.
  public var debugInfoReduced = false
  /// Whether the client should show the respawn screen on death.
  public var respawnScreenEnabled = true
  
  /// The difficulty of the server.
  public var difficulty = Difficulty.normal
  /// Whether the server is hardcode or not.
  public var isHardcore = false
  /// Whether the server's difficulty is locked for the player or not.
  public var isDifficultyLocked = true
  
  /// Creates an empty game with default properties. Starts the tick loop.
  public init() {
    tickScheduler.ticksPerSecond = 20
    tickScheduler.startTickLoop()
  }
  
  /// Updates the game with information received in a ``JoinGamePacket``.
  public mutating func update(packet: JoinGamePacket, client: Client) {
    maxPlayers = Int(packet.maxPlayers)
    maxViewDistance = packet.viewDistance
    debugInfoReduced = packet.reducedDebugInfo
    respawnScreenEnabled = packet.enableRespawnScreen
    isHardcore = packet.isHardcore
    
    player = Player(from: packet)
    world = World(from: packet, batching: client.batchWorldUpdates)
  }
  
  /// Sets the game's event bus. This is a method in case the game ever needs to listen to the event bus, this way means that the listener can be added again.
  public mutating func setEventBus(_ eventBus: EventBus) {
    self.eventBus = eventBus
  }
}
