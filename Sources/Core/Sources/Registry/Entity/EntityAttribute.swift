/// Attributes that are the same for every entity of a given kind (e.g. maximum health). Not all are present for a given entity.
public enum EntityAttribute: String, Codable {
  case maxHealth = "minecraft:generic.max_health"
  case armor = "minecraft:generic.armor"
  case armorToughness = "minecraft:generic.armor_toughness"
  case attackDamage = "minecraft:generic.attack_damage"
  case attackKnockback = "minecraft:generic.attack_knockback"
  case knockbackResistance = "minecraft:generic.knockback_resistance"
  case movementSpeed = "minecraft:generic.movement_speed"
  case flyingSpeed = "minecraft:generic.flying_speed"
  case followRange = "minecraft:generic.follow_range"
  case attackSpeed = "minecraft:generic.attack_speed"
  case luck = "minecraft:generic.luck"
  case horseJumpStrength = "minecraft:horse.jump_strength"
  case zombieSpawnReinforcement = "minecraft:zombie.spawn_reinforcements"
}
