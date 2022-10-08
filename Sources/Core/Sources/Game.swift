import Foundation
import FirebladeECS

/// Stores all of the game data such as entities, chunks and chat messages.
public struct Game {
  // MARK: Public properties

  /// The scheduler that runs the game's systems every 20th of a second.
  public var tickScheduler: TickScheduler
  /// The event bus for emitting events.
  public var eventBus: EventBus
  /// Maps Vanilla entity Ids to identifiers of entities in the ``Nexus``.
  private var entityIdToEntityIdentifier: [Int: EntityIdentifier] = [:]

  /// The world the player is currently connected to.
  private(set) public var world: World
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

  // MARK: Private properties

  /// A locked for managing safe access of ``nexus``.
  private let nexusLock = ReadWriteLock()
  /// The container for the game's entities. Strictly only contains what Minecraft counts as
  /// entities. Doesn't include block entities.
  private let nexus = Nexus()
  /// The player.
  private var player: Player
  /// The current input state (keyboard and mouse).
  private let inputState: InputState
  /// The current GUI state (f3 screen, inventory, etc).
  private let _guiState: GUIStateStorage

  // MARK: Init

  /// Creates a game with default properties. Creates the player. Starts the tick loop.
  public init(eventBus: EventBus, connection: ServerConnection? = nil) {
    self.eventBus = eventBus

    world = World(eventBus: eventBus)

    tickScheduler = TickScheduler(nexus, nexusLock: nexusLock, world)

    inputState = nexus.single(InputState.self).component
    _guiState = nexus.single(GUIStateStorage.self).component

    player = Player()
    var player = player
    player.add(to: &self)
    self.player = player

    // The order of the systems may seem weird, but it has to be this way so that the physics
    // behaves identically to vanilla
    tickScheduler.addSystem(PlayerFrictionSystem())
    tickScheduler.addSystem(PlayerGravitySystem())
    tickScheduler.addSystem(PlayerSmoothingSystem())
    tickScheduler.addSystem(PlayerInputSystem(connection, eventBus))
    tickScheduler.addSystem(PlayerFlightSystem())
    tickScheduler.addSystem(PlayerAccelerationSystem())
    tickScheduler.addSystem(PlayerJumpSystem())
    tickScheduler.addSystem(PlayerVelocitySystem())
    tickScheduler.addSystem(PlayerCollisionSystem())
    tickScheduler.addSystem(PlayerPositionSystem())

    tickScheduler.addSystem(EntitySmoothingSystem())
    tickScheduler.addSystem(EntityPacketHandlingSystem())
    tickScheduler.addSystem(EntityMovementSystem())

    if let connection = connection {
      tickScheduler.addSystem(PlayerPacketSystem(connection))
    }

    // Start tick loop
    tickScheduler.ticksPerSecond = 20
    tickScheduler.startTickLoop()
  }

  // MARK: Input

  /// Handles a key press.
  /// - Parameters:
  ///   - key: The pressed key if any.
  ///   - input: The pressed input if any.
  ///   - characters: The characters typed by the pressed key.
  public func press(key: Key?, input: Input?, characters: [Character] = []) { // swiftlint:disable:this cyclomatic_complexity
    nexusLock.acquireWriteLock()
    defer { nexusLock.unlock() }
    inputState.press(key: key, input: input, characters: characters)
  }

  /// Handles a key release.
  /// - Parameters:
  ///   - key: The released key if any.
  ///   - input: The released input if any.
  public func release(key: Key?, input: Input?) {
    nexusLock.acquireWriteLock()
    defer { nexusLock.unlock() }
    inputState.release(key: key, input: input)
  }

  /// Moves the mouse.
  /// - Parameters:
  ///   - deltaX: The change in mouse x.
  ///   - deltaY: The change in mouse y.
  public func moveMouse(_ deltaX: Float, _ deltaY: Float) {
    nexusLock.acquireWriteLock()
    defer { nexusLock.unlock() }
    inputState.moveMouse(deltaX, deltaY)
  }

  /// Gets a copy of the current GUI state.
  /// - Returns: A copy of the current GUI state.
  public func guiState() -> GUIState {
    nexusLock.acquireReadLock()
    defer { nexusLock.unlock() }
    return _guiState.inner
  }

  /// Mutates the GUI state using a provided action.
  /// - acquireLock: If `false`, a nexus lock will not be acquired. Use with caution.
  /// - action: Action to run on GUI state.
  public func mutateGUIState(acquireLock: Bool = true, action: (inout GUIState) -> Void) {
    if acquireLock { nexusLock.acquireWriteLock() }
    defer { if acquireLock { nexusLock.unlock() } }
    action(&_guiState.inner)
  }

  // MARK: Entity

  /// A method for creating entities in a thread-safe manor.
  ///
  /// The builder can handle up to 20 components. This should be enough in most cases but if not,
  /// components can be added to the entity directly, this is just more convenient. The builder can
  /// only work for up to 20 components because of a limitation regarding result builders.
  /// - Parameters:
  ///   - id: The id to create the entity with.
  ///   - builder: The builder that creates the components for the entity.
  ///   - action: An action to perform on the entity once it's created.
  public mutating func createEntity(
    id: Int,
    @ComponentsBuilder using builder: () -> [Component],
    action: ((Entity) -> Void)? = nil
  ) {
    nexusLock.acquireWriteLock()
    defer { nexusLock.unlock() }

    let entity = nexus.createEntity(with: builder())
    entityIdToEntityIdentifier[id] = entity.identifier
    action?(entity)
  }

  /// Allows thread safe access to a given entity.
  /// - Parameters:
  ///   - id: The id of the entity to access.
  ///   - action: The action to perform on the entity if it exists.
  public func accessEntity(id: Int, action: (Entity) -> Void) {
    nexusLock.acquireWriteLock()
    defer { nexusLock.unlock() }

    if let identifier = entityIdToEntityIdentifier[id] {
      action(nexus.entity(from: identifier))
    }
  }

  /// Allows thread safe access to a given component.
  /// - Parameters:
  ///   - entityId: The id of the entity with the component.
  ///   - componentType: The type of component to access.
  ///   - acquireLock: If `false`, no lock is acquired. Only use if you know what you're doing.
  ///   - action: The action to perform on the component if the entity exists and contains that component.
  public func accessComponent<T: Component>(entityId: Int, _ componentType: T.Type, acquireLock: Bool = true, action: (T) -> Void) {
    if acquireLock { nexusLock.acquireWriteLock() }
    defer { if acquireLock { nexusLock.unlock() } }

    guard
      let identifier = entityIdToEntityIdentifier[entityId],
      let component = nexus.entity(from: identifier).get(component: T.self)
    else {
      return
    }

    action(component)
  }

  /// Removes the entity with the given vanilla id from the game if it exists.
  /// - Parameter id: The id of the entity to remove.
  public func removeEntity(id: Int) {
    nexusLock.acquireWriteLock()
    defer { nexusLock.unlock() }

    if let identifier = entityIdToEntityIdentifier[id] {
      nexus.destroy(entityId: identifier)
    }
  }

  /// Updates an entity's id if it exists.
  /// - Parameters:
  ///   - id: The current id of the entity.
  ///   - newId: The new id for the entity.
  public mutating func updateEntityId(_ id: Int, to newId: Int) {
    nexusLock.acquireWriteLock()
    defer { nexusLock.unlock() }

    if let identifier = entityIdToEntityIdentifier.removeValue(forKey: id) {
      entityIdToEntityIdentifier[newId] = identifier
      if let component = nexus.entity(from: identifier).get(component: EntityId.self) {
        component.id = newId
      }
    }
  }

  /// Allows thread safe access to the nexus.
  /// - Parameter action: The action to perform on the nexus.
  public func accessNexus(action: (Nexus) -> Void) {
    nexusLock.acquireWriteLock()
    defer { nexusLock.unlock() }

    action(nexus)
  }

  /// Allows thread safe access to the player.
  /// - Parameter action: The action to perform on the player.
  public func accessPlayer(action: (Player) -> Void) {
    nexusLock.acquireWriteLock()
    defer { nexusLock.unlock() }

    action(player)
  }

  /// Queues handling of an entity-related packet to occur during the next game tick.
  /// - Parameters:
  ///   - packet: The packet to queue.
  ///   - client: The client to handle the packet for.
  public mutating func handleDuringTick(_ packet: ClientboundEntityPacket, client: Client) {
    nexusLock.acquireWriteLock()
    defer { nexusLock.unlock() }

    let packetStore = nexus.single(ClientboundEntityPacketStore.self).component
    packetStore.add(packet, client: client)
  }

  // MARK: Player

  /// Gets the position of the block currently targeted by the player.
  public func targetedBlock() -> BlockPosition? {
    var ray: Ray = Ray(origin: .zero, direction: .zero)
    
    accessPlayer { player in
      ray = player.ray
    }

    for position in VoxelRay(along: ray, count: 7) {
      let block = world.getBlock(at: position)
      let boundingBox = block.shape.outlineShape.offset(by: position.doubleVector)
      if let distance = boundingBox.intersectionDistance(with: ray) {
        // TODO: Don't hardcode reach
        guard distance <= 6 else {
          break
        }

        return position
      }
    }

    return nil
  }
  
  /// Gets current gamemode of the player
  public func currentGamemode() -> Gamemode? {
    var gamemode: Gamemode? = nil
    accessPlayer { player in
      gamemode = player.gamemode.gamemode
    }
    
    return gamemode
  }

  // MARK: Lifecycle

  /// Updates the game with information received in a ``JoinGamePacket``.
  public mutating func update(packet: JoinGamePacket, client: Client) {
    // TODO: not threadsafe
    maxPlayers = Int(packet.maxPlayers)
    maxViewDistance = packet.viewDistance
    debugInfoReduced = packet.reducedDebugInfo
    respawnScreenEnabled = packet.enableRespawnScreen
    isHardcore = packet.isHardcore

    var playerEntityId: Int?
    accessPlayer { player in
      player.playerAttributes.previousGamemode = packet.previousGamemode
      player.gamemode.gamemode = packet.gamemode
      player.playerAttributes.isHardcore = packet.isHardcore
      playerEntityId = player.entityId.id
    }

    if let playerEntityId = playerEntityId {
      updateEntityId(playerEntityId, to: packet.playerEntityId)
    }

    changeWorld(to: World(from: packet, eventBus: client.eventBus))
  }

  /// Sets the game's event bus. This is a method in case the game ever needs to listen to the event
  /// bus, this way means that the listener can be added again.
  public mutating func setEventBus(_ eventBus: EventBus) {
    self.eventBus = eventBus
    self.world.eventBus = eventBus
  }

  /// Changes to a new world.
  /// - Parameter world: The new world.
  public mutating func changeWorld(to newWorld: World) {
    // TODO: Make this threadsafe
    self.world = newWorld
    tickScheduler.setWorld(to: newWorld)
  }
}
