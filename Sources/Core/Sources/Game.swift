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
  private let inputState: Single<InputState>

  // MARK: Init

  /// Creates a game with default properties. Creates the player. Starts the tick loop.
  public init(eventBus: EventBus, connection: ServerConnection? = nil) {
    self.eventBus = eventBus

    world = World(eventBus: eventBus)

    tickScheduler = TickScheduler(nexus, nexusLock: nexusLock, world)

    inputState = nexus.single(InputState.self)

    player = Player()
    var player = player
    player.add(to: &self)
    self.player = player

    // The order of the systems may seem weird, but it has to be this way so that the physics
    // behaves identically to vanilla
    tickScheduler.addSystem(PlayerFrictionSystem())
    tickScheduler.addSystem(PlayerGravitySystem())
    tickScheduler.addSystem(PlayerSmoothingSystem())
    tickScheduler.addSystem(PlayerInputSystem())
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

  /// Presses an input.
  /// - Parameter input: The input to press.
  public func press(_ input: Input) { // swiftlint:disable:this cyclomatic_complexity
    nexusLock.acquireWriteLock()
    defer { nexusLock.unlock() }

    // Movement inputs are handled by the ECS
    inputState.component.press(input)

    // Handle non-movement inputs
    switch input {
      case .changePerspective:
        player.camera.cyclePerspective()
      case .slot1:
        player.inventory.selectedHotbarSlot = 0
      case .slot2:
        player.inventory.selectedHotbarSlot = 1
      case .slot3:
        player.inventory.selectedHotbarSlot = 2
      case .slot4:
        player.inventory.selectedHotbarSlot = 3
      case .slot5:
        player.inventory.selectedHotbarSlot = 4
      case .slot6:
        player.inventory.selectedHotbarSlot = 5
      case .slot7:
        player.inventory.selectedHotbarSlot = 6
      case .slot8:
        player.inventory.selectedHotbarSlot = 7
      case .slot9:
        player.inventory.selectedHotbarSlot = 8
      case .nextSlot:
        player.inventory.selectedHotbarSlot = (player.inventory.selectedHotbarSlot + 1) % 9
      case .previousSlot:
        player.inventory.selectedHotbarSlot = (player.inventory.selectedHotbarSlot + 8) % 9
      default:
        break
    }
  }

  /// Releases an input.
  /// - Parameter input: The input to release.
  public func release(_ input: Input) {
    nexusLock.acquireWriteLock()
    defer { nexusLock.unlock() }
    inputState.component.release(input)
  }

  /// Moves the mouse.
  /// - Parameters:
  ///   - deltaX: The change in mouse x.
  ///   - deltaY: The change in mouse y.
  public func moveMouse(_ deltaX: Float, _ deltaY: Float) {
    nexusLock.acquireWriteLock()
    defer { nexusLock.unlock() }
    inputState.component.moveMouse(deltaX, deltaY)
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
  public mutating func accessPlayer(action: (inout Player) -> Void) {
    nexusLock.acquireWriteLock()
    defer { nexusLock.unlock() }

    action(&player)
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
