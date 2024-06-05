import FirebladeECS
import Foundation

/// Stores all of the game data such as entities, chunks and chat messages.
public final class Game: @unchecked Sendable {
  // MARK: Public properties

  /// The scheduler that runs the game's systems every 20th of a second (by default).
  public private(set) var tickScheduler: TickScheduler
  /// The event bus for emitting events.
  public private(set) var eventBus: EventBus
  /// Maps Vanilla entity Ids to identifiers of entities in the ``Nexus``.
  private var entityIdToEntityIdentifier: [Int: EntityIdentifier] = [:]

  /// The world the player is currently connected to.
  private(set) public var world: World
  /// The list of all players in the game.
  public var tabList = TabList()
  /// The names of all worlds in this game
  public var worldNames: [Identifier] = []
  /// A structure holding information about all of the dimensions (sent by server).
  public var dimensions = [Dimension.overworld]
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

  #if DEBUG_LOCKS
    /// A locked for managing safe access of ``nexus``.
    public let nexusLock = ReadWriteLock()
  #else
    /// A locked for managing safe access of ``nexus``.
    private let nexusLock = ReadWriteLock()
  #endif
  /// The container for the game's entities. Strictly only contains what Minecraft counts as
  /// entities. Doesn't include block entities.
  private let nexus = Nexus()
  /// The player.
  private var player: Player
  /// The current input state (keyboard and mouse).
  private let inputState: InputState

  /// A lock for managing safe access of ``gui``.
  private let guiLock = ReadWriteLock()
  /// The current GUI state (f3 screen, inventory, etc).
  private let gui: InGameGUI
  /// Storage for the current GUI state. Protected by ``nexusLock`` since it's stored in the
  /// nexus.
  private let _guiState: GUIStateStorage

  // MARK: Init

  /// Creates a game with default properties. Creates the player. Starts the tick loop.
  public init(
    eventBus: EventBus,
    configuration: ClientConfiguration,
    connection: ServerConnection? = nil,
    font: Font,
    locale: MinecraftLocale
  ) {
    self.eventBus = eventBus

    world = World(eventBus: eventBus)

    tickScheduler = TickScheduler(nexus, nexusLock: nexusLock, world)

    inputState = nexus.single(InputState.self).component
    gui = InGameGUI()
    _guiState = nexus.single(GUIStateStorage.self).component

    player = Player()
    var player = player
    player.add(to: self)
    self.player = player

    // The order of the systems may seem weird, but it has to be this way so that the physics
    // behaves identically to vanilla
    tickScheduler.addSystem(PlayerFrictionSystem())
    tickScheduler.addSystem(PlayerClimbSystem())
    tickScheduler.addSystem(PlayerGravitySystem())
    tickScheduler.addSystem(PlayerSmoothingSystem())
    tickScheduler.addSystem(PlayerBlockBreakingSystem(connection, self))
    // TODO: Make sure that font gets updated when resource pack gets updated, will likely
    //   require significant refactoring if we wanna do it right (as in not just hacking it
    //   together for the specific case of PlayerInputSystem); proper resource pack propagation
    //   will probably take quite a bit of work.
    tickScheduler.addSystem(
      PlayerInputSystem(connection, self, eventBus, configuration, font, locale)
    )
    tickScheduler.addSystem(PlayerFlightSystem())
    tickScheduler.addSystem(PlayerAccelerationSystem())
    tickScheduler.addSystem(PlayerJumpSystem())
    tickScheduler.addSystem(PlayerVelocitySystem())
    tickScheduler.addSystem(PlayerCollisionSystem())
    tickScheduler.addSystem(PlayerPositionSystem())
    tickScheduler.addSystem(PlayerFOVSystem())

    tickScheduler.addSystem(EntitySmoothingSystem())
    tickScheduler.addSystem(EntityPacketHandlingSystem())
    tickScheduler.addSystem(EntityMovementSystem())

    if let connection = connection {
      tickScheduler.addSystem(PlayerPacketSystem(connection))
    }

    // Start tick loop
    tickScheduler.startTickLoop()
  }

  // MARK: Input

  /// Handles a key press.
  /// - Parameters:
  ///   - key: The pressed key if any.
  ///   - input: The pressed input if any.
  ///   - characters: The characters typed by the pressed key.
  public func press(key: Key?, input: Input?, characters: [Character] = []) {  // swiftlint:disable:this cyclomatic_complexity
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

  /// Releases all inputs. That includes keys.
  public func releaseAllInputs() {
    nexusLock.acquireWriteLock()
    defer { nexusLock.unlock() }
    inputState.releaseAll()
  }

  /// Moves the mouse.
  ///
  /// See ``Client/moveMouse(x:y:deltaX:deltaY:)`` for the reasoning behind
  /// having both absolute and relative parameters (it's currently necessary
  /// but could be fixed by cleaning up the input handling architecture).
  /// - Parameters:
  ///   - x: The absolute mouse x (relative to the play area's top left corner).
  ///   - y: The absolute mouse y (relative to the play area's top left corner).
  ///   - deltaX: The change in mouse x.
  ///   - deltaY: The change in mouse y.
  public func moveMouse(x: Float, y: Float, deltaX: Float, deltaY: Float) {
    nexusLock.acquireWriteLock()
    defer { nexusLock.unlock() }
    inputState.moveMouse(x: x, y: y, deltaX: deltaX, deltaY: deltaY)
  }

  /// Moves the left thumbstick.
  /// - Parameters:
  ///   - x: The x positon.
  ///   - y: The y position.
  public func moveLeftThumbstick(_ x: Float, _ y: Float) {
    nexusLock.acquireWriteLock()
    defer { nexusLock.unlock() }
    inputState.moveLeftThumbstick(x, y)
  }

  /// Moves the right thumbstick.
  /// - Parameters:
  ///   - x: The x positon.
  ///   - y: The y position.
  public func moveRightThumbstick(_ x: Float, _ y: Float) {
    nexusLock.acquireWriteLock()
    defer { nexusLock.unlock() }
    inputState.moveRightThumbstick(x, y)
  }

  public func accessInputState<R>(acquireLock: Bool = true, action: (InputState) -> R) -> R {
    if acquireLock { nexusLock.acquireWriteLock() }
    defer { if acquireLock { nexusLock.unlock() } }
    return action(inputState)
  }

  /// Gets a copy of the current GUI state.
  /// - Returns: A copy of the current GUI state.
  public func guiState() -> GUIState {
    nexusLock.acquireReadLock()
    defer { nexusLock.unlock() }
    return _guiState.inner
  }

  /// Handles a received chat message.
  public func receiveChatMessage(acquireLock: Bool = true, _ message: ChatMessage) {
    if acquireLock { nexusLock.acquireWriteLock() }
    defer { if acquireLock { nexusLock.unlock() } }
    _guiState.chat.add(message)
  }

  /// Mutates the GUI state with a given action.
  public func mutateGUIState<R>(acquireLock: Bool = true, action: (inout GUIState) throws -> R)
    rethrows -> R
  {
    if acquireLock { nexusLock.acquireWriteLock() }
    defer { if acquireLock { nexusLock.unlock() } }
    return try action(&_guiState.inner)
  }

  /// Updates the GUI's render statistics.
  public func updateRenderStatistics(acquireLock: Bool = true, to statistics: RenderStatistics) {
    mutateGUIState(acquireLock: false) { state in
      state.renderStatistics = statistics
    }
  }

  /// Compile the in-game GUI to a renderable.
  /// - acquireGUILock: If `false`, a GUI lock will not be acquired. Use with caution.
  /// - acquireNexusLock: If `false`, a GUI lock will not be acquired (otherwise a nexus lock will be
  ///   acquired if guiState isn't supplied). Use with caution.
  /// - connection: Used to notify the server of window interactions and related operations.
  /// - font: Font to use when rendering, used to compute text sizing and wrapping.
  /// - locale: Locale used to resolve chat message content.
  /// - guiState: Avoids the need for this function to call out to the nexus redundantly if the caller already
  ///   has a reference to the gui state.
  public func compileGUI(
    acquireGUILock: Bool = true,
    acquireNexusLock: Bool = true,
    withFont font: Font,
    locale: MinecraftLocale,
    connection: ServerConnection?,
    guiState: GUIStateStorage? = nil
  ) -> GUIElement.GUIRenderable {
    // Acquire the nexus lock first as that's the one that threads can be sitting inside of with `Game.accessNexus`.
    // If we get the GUI lock first then the renderer can be waiting for the nexus lock while PlayerInputSystem is
    // sitting with a nexus lock and waiting for a gui lock.
    // TODO: Formalize the idea of keeping a consistent 'topological' ordering for locks throughout the project.
    //   I think that would prevent this class of deadlocks.
    var state: GUIStateStorage
    if let guiState = guiState {
      state = guiState
    } else {
      if acquireNexusLock { nexusLock.acquireWriteLock() }
      state = nexus.single(GUIStateStorage.self).component
    }
    if acquireGUILock { guiLock.acquireWriteLock() }
    defer { if acquireGUILock { guiLock.unlock() } }
    defer { if acquireNexusLock && guiState == nil { nexusLock.unlock() } }
    return gui.content(game: self, connection: connection, state: state)
      .resolveConstraints(availableSize: state.drawableSize, font: font, locale: locale)
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
  public func createEntity(
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
  public func accessEntity(id: Int, acquireLock: Bool = true, action: (Entity) -> Void) {
    if acquireLock { nexusLock.acquireWriteLock() }
    defer { if acquireLock { nexusLock.unlock() } }

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
  public func accessComponent<T: Component>(
    entityId: Int, _ componentType: T.Type, acquireLock: Bool = true, action: (T) -> Void
  ) {
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
  public func removeEntity(acquireLock: Bool = true, id: Int) {
    if acquireLock { nexusLock.acquireWriteLock() }
    defer { if acquireLock { nexusLock.unlock() } }

    if let identifier = entityIdToEntityIdentifier[id] {
      nexus.destroy(entityId: identifier)
    }
  }

  /// Updates an entity's id if it exists.
  /// - Parameters:
  ///   - id: The current id of the entity.
  ///   - newId: The new id for the entity.
  public func updateEntityId(_ id: Int, to newId: Int) {
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
  /// - Parameters:
  ///   - acquireLock: If `false`, no lock is acquired. Only use if you know what you're doing.
  ///   - action: The action to perform on the player.
  public func accessPlayer<T>(acquireLock: Bool = true, action: (Player) throws -> T) rethrows -> T
  {
    if acquireLock { nexusLock.acquireWriteLock() }
    defer { if acquireLock { nexusLock.unlock() } }

    return try action(player)
  }

  /// Queues handling of an entity-related packet to occur during the next game tick.
  /// - Parameters:
  ///   - packet: The packet to queue.
  ///   - client: The client to handle the packet for.
  public func handleDuringTick(_ packet: ClientboundEntityPacket, client: Client) {
    nexusLock.acquireWriteLock()
    defer { nexusLock.unlock() }

    let packetStore = nexus.single(ClientboundEntityPacketStore.self).component
    packetStore.add(packet, client: client)
  }

  // MARK: Player

  /// Gets the position of the block currently targeted by the player.
  /// - Parameters:
  ///   - acquireLock: If `false`, no locks are acquired. Only use if you know what you're doing.
  public func targetedBlockIgnoringEntities(acquireLock: Bool = true) -> Targeted<BlockPosition>? {
    if acquireLock {
      nexusLock.acquireReadLock()
    }

    let ray = player.ray

    if acquireLock {
      nexusLock.unlock()
    }

    for position in VoxelRay(along: ray, count: 7) {
      let block = world.getBlock(at: position, acquireLock: acquireLock)
      let boundingBox = block.shape.outlineShape.offset(by: position.doubleVector)
      if let (distance, face) = boundingBox.intersectionDistanceAndFace(with: ray) {
        // TODO: Don't hardcode reach here
        guard distance <= 6 else {
          break
        }

        let targetedPosition = ray.direction * distance + ray.origin
        return Targeted<BlockPosition>(
          target: position,
          distance: distance,
          face: face,
          targetedPosition: targetedPosition
        )
      }
    }

    return nil
  }

  public func targetedBlock(acquireLock: Bool = true) -> Targeted<BlockPosition>? {
    guard let targetedThing = targetedThing(acquireLock: acquireLock) else {
      return nil
    }

    guard case let .block(position) = targetedThing.target else {
      return nil
    }

    return targetedThing.map(constant(position))
  }

  // TODO: Make a value type for entity ids so that this doesn't return a targeted integer (just feels confusing).
  /// - Returns: The id of the entity targeted by the player, if any.
  public func targetedEntityIgnoringBlocks(acquireLock: Bool = true) -> Targeted<Int>? {
    if acquireLock { nexusLock.acquireReadLock() }
    defer { if acquireLock { nexusLock.unlock() } }

    let playerPosition = player.position.vector
    let playerRay = player.ray

    let family = nexus.family(
      requiresAll: EntityId.self,
      EntityPosition.self,
      EntityHitBox.self,
      excludesAll: ClientPlayerEntity.self
    )

    var candidate: Targeted<Int>?
    for (id, position, hitbox) in family {
      guard (playerPosition - position.vector).magnitude < 4 else {
        continue
      }

      guard
        let (distance, face) = hitbox.aabb(at: position.vector).intersectionDistanceAndFace(
          with: playerRay)
      else {
        continue
      }

      let newCandidate = Targeted<Int>(
        target: id.id,
        distance: distance,
        face: face,
        targetedPosition: playerRay.direction * distance + playerRay.origin
      )

      if let currentCandidate = candidate {
        if distance < currentCandidate.distance {
          candidate = newCandidate
        }
      } else {
        candidate = newCandidate
      }
    }

    return candidate
  }

  public func targetedEntity(acquireLock: Bool = true) -> Targeted<Int>? {
    guard let targetedThing = targetedThing(acquireLock: acquireLock) else {
      return nil
    }

    guard case let .entity(id) = targetedThing.target else {
      return nil
    }

    return targetedThing.map(constant(id))
  }

  /// - Returns: The closest thing targeted by the player.
  public func targetedThing(acquireLock: Bool = true) -> Targeted<Thing>? {
    let targetedBlock = targetedBlockIgnoringEntities(acquireLock: acquireLock)
    let targetedEntity = targetedEntityIgnoringBlocks(acquireLock: acquireLock)
    if let block = targetedBlock, let entity = targetedEntity {
      if block.distance < entity.distance {
        return block.map(Thing.block)
      } else {
        return entity.map(Thing.entity)
      }
    } else if let block = targetedBlock {
      return block.map(Thing.block)
    } else if let entity = targetedEntity {
      return entity.map(Thing.entity)
    } else {
      return nil
    }
  }

  /// Gets current gamemode of the player.
  public func currentGamemode() -> Gamemode? {
    var gamemode: Gamemode? = nil
    accessPlayer { player in
      gamemode = player.gamemode.gamemode
    }

    return gamemode
  }

  /// Calculates the current fov multiplier from various factors such as movement speed
  /// and whether the player is flying. Emulates vanilla's behaviour.
  public func fovMultiplier() -> Float {
    return accessPlayer { player in
      return player.fov.smoothMultiplier
    }
  }

  // MARK: Lifecycle

  /// Sets the game's event bus. This is a method in case the game ever needs to listen to the event
  /// bus, this way means that the listener can be added again.
  public func setEventBus(_ eventBus: EventBus) {
    self.eventBus = eventBus
    self.world.eventBus = eventBus
  }

  /// Changes to a new world.
  /// - Parameter world: The new world.
  public func changeWorld(to newWorld: World) {
    // TODO: Make this threadsafe
    self.world = newWorld
    tickScheduler.setWorld(to: newWorld)
  }

  /// Stops the tick scheduler.
  public func stopTickScheduler() {
    tickScheduler.cancel()
  }
}
