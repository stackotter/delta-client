import Foundation
import FirebladeECS

/// Stores all of the game data such as entities, chunks and chat messages.
public struct Game {
  // MARK: Public properties
  
  /// The container for the game's entities. Strictly only contains what Minecraft counts as entities. Doesn't include block entities.
  public let nexus = Nexus()
  /// The scheduler that runs the game's systems every 20th of a second.
  public var tickScheduler: TickScheduler
  /// The event bus for emitting events.
  public var eventBus: EventBus
  /// Maps Vanilla entity Ids to identifiers of entities in the ``Nexus``.
  private var entityIdToEntityIdentifier: [Int: EntityIdentifier] = [:]
  
  /// The player.
  public var player: Player
  /// The world the player is currently connected to.
  public var world: World
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
  
  /// The system that handles entity physics.
  public var physicsSystem = PhysicsSystem()
  
  // MARK: Init
  
  /// Creates a game with default properties. Creates the player. Starts the tick loop.
  public init(eventBus: EventBus) {
    self.eventBus = eventBus
    
    tickScheduler = TickScheduler(nexus)
    
    world = World(eventBus: eventBus)
    
    player = Player()
    var player = player
    player.add(to: &self)
    self.player = player
    
    // Add systems
    tickScheduler.addSystem(physicsSystem)
    
    // Start tick loop
    tickScheduler.ticksPerSecond = 20
    tickScheduler.startTickLoop()
  }
  
  // MARK: Entity
  
  /// A custom method for creating entities with value type components.
  ///
  /// The builder can handle up to 20 components. This should be enough in most cases but if not, components can be added to the nexus directly, this is just more convenient.
  /// The builder can only work for up to 20 components because of a limitation regarding result builders.
  @discardableResult
  public mutating func createEntity(id: Int, @ComponentsBuilder using builder: () -> [Component]) -> Entity {
    let entity = nexus.createEntity(with: builder())
    entityIdToEntityIdentifier[id] = entity.identifier
    return entity
  }
  
  /// Returns the entity with the given vanilla id if it exists.
  public func entity(id: Int) -> Entity? {
    if let identifier = entityIdToEntityIdentifier[id] {
      return nexus.entity(from: identifier)
    }
    return nil
  }
  
  /// Returns the entity with the given vanilla id if it exists.
  public func component<T: Component>(entityId: Int, _ componentType: T.Type) -> T? {
    if let identifier = entityIdToEntityIdentifier[entityId] {
      return nexus.entity(from: identifier).get(component: T.self)
    }
    return nil
  }
  
  /// Removes the entity with the given vanilla id from the game if it exists.
  public func removeEntity(id: Int) {
    if let identifier = entityIdToEntityIdentifier[id] {
      nexus.destroy(entityId: identifier)
    }
  }
  
  /// Updates an entity's id if it exists.
  public mutating func updateEntityId(_ id: Int, to newId: Int) {
    if let identifier = entityIdToEntityIdentifier.removeValue(forKey: id) {
      entityIdToEntityIdentifier[newId] = identifier
      if let component = nexus.entity(from: identifier).get(component: EntityId.self) {
        component.id = newId
      }
    }
  }
  
  // MARK: Lifecycle
  
  /// Updates the game with information received in a ``JoinGamePacket``.
  public mutating func update(packet: JoinGamePacket, client: Client) {
    maxPlayers = Int(packet.maxPlayers)
    maxViewDistance = packet.viewDistance
    debugInfoReduced = packet.reducedDebugInfo
    respawnScreenEnabled = packet.enableRespawnScreen
    isHardcore = packet.isHardcore
    
    player.attributes.previousGamemode = packet.previousGamemode
    player.gamemode.gamemode = packet.gamemode
    player.attributes.isHardcore = packet.isHardcore
    updateEntityId(player.entityId.id, to: packet.playerEntityId)
    
    world = World(from: packet, eventBus: client.eventBus)
  }
  
  /// Sets the game's event bus. This is a method in case the game ever needs to listen to the event bus, this way means that the listener can be added again.
  public mutating func setEventBus(_ eventBus: EventBus) {
    self.eventBus = eventBus
    self.world.eventBus = eventBus
  }
}
