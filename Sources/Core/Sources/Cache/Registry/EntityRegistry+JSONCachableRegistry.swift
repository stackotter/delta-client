extension EntityRegistry: JSONCachableRegistry {
  public static func getCacheFileName() -> String {
    "entities.json"
  }
}
