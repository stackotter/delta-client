/// A marker for packets that must be handled during the game tick.
///
/// > Warning: Packets conforming to this must not acquire a nexus lock because this will cause
/// > deadlocks. The tick scheduler will already have a lock by the time the packets are handled.
public protocol ClientboundEntityPacket: ClientboundPacket {}
