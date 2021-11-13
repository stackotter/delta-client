import FirebladeECS

extension Nexus {
  /// A custom method for creating entities with value type components.
  ///
  /// The builder can handle up to 20 components. This should be enough in most cases but if not components can be added another way, this is just more convenient.
  /// The builder can only work for up to 20 components because of a limitation regarding result builders.
  @discardableResult
  public func createDeltaEntity(@BoxedComponentsBuilder using builder: () -> [Component]) -> Entity {
    self.createEntity(with: builder())
  }
}

@resultBuilder
public enum BoxedComponentsBuilder {
  public static func buildBlock() -> [Component] {
    []
  }
  
  public static func buildBlock<T1>(_ comp1: T1) -> [Component] {
    [Box(comp1)]
  }
  
  public static func buildBlock<T1, T2>(_ comp1: T1, _ comp2: T2) -> [Component] {
    [Box(comp1), Box(comp2)]
  }
  
  public static func buildBlock<T1, T2, T3>(_ comp1: T1, _ comp2: T2, _ comp3: T3) -> [Component] {
    [Box(comp1), Box(comp2), Box(comp3)]
  }
  
  public static func buildBlock<T1, T2, T3, T4>(_ comp1: T1, _ comp2: T2, _ comp3: T3, _ comp4: T4) -> [Component] {
    [Box(comp1), Box(comp2), Box(comp3), Box(comp4)]
  }
  
  public static func buildBlock<T1, T2, T3, T4, T5>(_ comp1: T1, _ comp2: T2, _ comp3: T3, _ comp4: T4, _ comp5: T5) -> [Component] {
    [Box(comp1), Box(comp2), Box(comp3), Box(comp4), Box(comp5)]
  }
  
  public static func buildBlock<T1, T2, T3, T4, T5, T6>(_ comp1: T1, _ comp2: T2, _ comp3: T3, _ comp4: T4, _ comp5: T5, _ comp6: T6) -> [Component] {
    [Box(comp1), Box(comp2), Box(comp3), Box(comp4), Box(comp5), Box(comp6)]
  }
  
  public static func buildBlock<T1, T2, T3, T4, T5, T6, T7>(_ comp1: T1, _ comp2: T2, _ comp3: T3, _ comp4: T4, _ comp5: T5, _ comp6: T6, _ comp7: T7) -> [Component] {
    [Box(comp1), Box(comp2), Box(comp3), Box(comp4), Box(comp5), Box(comp6), Box(comp7)]
  }
  
  public static func buildBlock<T1, T2, T3, T4, T5, T6, T7, T8>(_ comp1: T1, _ comp2: T2, _ comp3: T3, _ comp4: T4, _ comp5: T5, _ comp6: T6, _ comp7: T7, _ comp8: T8) -> [Component] {
    [Box(comp1), Box(comp2), Box(comp3), Box(comp4), Box(comp5), Box(comp6), Box(comp7), Box(comp8)]
  }
  
  public static func buildBlock<T1, T2, T3, T4, T5, T6, T7, T8, T9>(_ comp1: T1, _ comp2: T2, _ comp3: T3, _ comp4: T4, _ comp5: T5, _ comp6: T6, _ comp7: T7, _ comp8: T8, _ comp9: T9) -> [Component] {
    [Box(comp1), Box(comp2), Box(comp3), Box(comp4), Box(comp5), Box(comp6), Box(comp7), Box(comp8), Box(comp9)]
  }
  
  public static func buildBlock<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10>(_ comp1: T1, _ comp2: T2, _ comp3: T3, _ comp4: T4, _ comp5: T5, _ comp6: T6, _ comp7: T7, _ comp8: T8, _ comp9: T9, _ comp10: T10) -> [Component] {
    [Box(comp1), Box(comp2), Box(comp3), Box(comp4), Box(comp5), Box(comp6), Box(comp7), Box(comp8), Box(comp9), Box(comp10)]
  }
  
  public static func buildBlock<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11>(_ comp1: T1, _ comp2: T2, _ comp3: T3, _ comp4: T4, _ comp5: T5, _ comp6: T6, _ comp7: T7, _ comp8: T8, _ comp9: T9, _ comp10: T10, _ comp11: T11) -> [Component] {
    [Box(comp1), Box(comp2), Box(comp3), Box(comp4), Box(comp5), Box(comp6), Box(comp7), Box(comp8), Box(comp9), Box(comp10), Box(comp11)]
  }
  
  public static func buildBlock<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12>(_ comp1: T1, _ comp2: T2, _ comp3: T3, _ comp4: T4, _ comp5: T5, _ comp6: T6, _ comp7: T7, _ comp8: T8, _ comp9: T9, _ comp10: T10, _ comp11: T11, _ comp12: T12) -> [Component] {
    [Box(comp1), Box(comp2), Box(comp3), Box(comp4), Box(comp5), Box(comp6), Box(comp7), Box(comp8), Box(comp9), Box(comp10), Box(comp11), Box(comp12)]
  }
  
  public static func buildBlock<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13>(_ comp1: T1, _ comp2: T2, _ comp3: T3, _ comp4: T4, _ comp5: T5, _ comp6: T6, _ comp7: T7, _ comp8: T8, _ comp9: T9, _ comp10: T10, _ comp11: T11, _ comp12: T12, _ comp13: T13) -> [Component] {
    [Box(comp1), Box(comp2), Box(comp3), Box(comp4), Box(comp5), Box(comp6), Box(comp7), Box(comp8), Box(comp9), Box(comp10), Box(comp11), Box(comp12), Box(comp13)]
  }
  
  public static func buildBlock<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T14>(_ comp1: T1, _ comp2: T2, _ comp3: T3, _ comp4: T4, _ comp5: T5, _ comp6: T6, _ comp7: T7, _ comp8: T8, _ comp9: T9, _ comp10: T10, _ comp11: T11, _ comp12: T12, _ comp13: T13, _ comp14: T14) -> [Component] {
    [Box(comp1), Box(comp2), Box(comp3), Box(comp4), Box(comp5), Box(comp6), Box(comp7), Box(comp8), Box(comp9), Box(comp10), Box(comp11), Box(comp12), Box(comp13), Box(comp14)]
  }
  
  public static func buildBlock<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T14, T15>(_ comp1: T1, _ comp2: T2, _ comp3: T3, _ comp4: T4, _ comp5: T5, _ comp6: T6, _ comp7: T7, _ comp8: T8, _ comp9: T9, _ comp10: T10, _ comp11: T11, _ comp12: T12, _ comp13: T13, _ comp14: T14, _ comp15: T15) -> [Component] {
    [Box(comp1), Box(comp2), Box(comp3), Box(comp4), Box(comp5), Box(comp6), Box(comp7), Box(comp8), Box(comp9), Box(comp10), Box(comp11), Box(comp12), Box(comp13), Box(comp14), Box(comp15)]
  }
  
  public static func buildBlock<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T14, T15, T16>(_ comp1: T1, _ comp2: T2, _ comp3: T3, _ comp4: T4, _ comp5: T5, _ comp6: T6, _ comp7: T7, _ comp8: T8, _ comp9: T9, _ comp10: T10, _ comp11: T11, _ comp12: T12, _ comp13: T13, _ comp14: T14, _ comp15: T15, _ comp16: T16) -> [Component] {
    [Box(comp1), Box(comp2), Box(comp3), Box(comp4), Box(comp5), Box(comp6), Box(comp7), Box(comp8), Box(comp9), Box(comp10), Box(comp11), Box(comp12), Box(comp13), Box(comp14), Box(comp15), Box(comp16)]
  }
  
  public static func buildBlock<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T14, T15, T16, T17>(_ comp1: T1, _ comp2: T2, _ comp3: T3, _ comp4: T4, _ comp5: T5, _ comp6: T6, _ comp7: T7, _ comp8: T8, _ comp9: T9, _ comp10: T10, _ comp11: T11, _ comp12: T12, _ comp13: T13, _ comp14: T14, _ comp15: T15, _ comp16: T16, _ comp17: T17) -> [Component] {
    [Box(comp1), Box(comp2), Box(comp3), Box(comp4), Box(comp5), Box(comp6), Box(comp7), Box(comp8), Box(comp9), Box(comp10), Box(comp11), Box(comp12), Box(comp13), Box(comp14), Box(comp15), Box(comp16), Box(comp17)]
  }
  
  public static func buildBlock<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T14, T15, T16, T17, T18>(_ comp1: T1, _ comp2: T2, _ comp3: T3, _ comp4: T4, _ comp5: T5, _ comp6: T6, _ comp7: T7, _ comp8: T8, _ comp9: T9, _ comp10: T10, _ comp11: T11, _ comp12: T12, _ comp13: T13, _ comp14: T14, _ comp15: T15, _ comp16: T16, _ comp17: T17, _ comp18: T18) -> [Component] {
    [Box(comp1), Box(comp2), Box(comp3), Box(comp4), Box(comp5), Box(comp6), Box(comp7), Box(comp8), Box(comp9), Box(comp10), Box(comp11), Box(comp12), Box(comp13), Box(comp14), Box(comp15), Box(comp16), Box(comp17), Box(comp18)]
  }
  
  public static func buildBlock<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T14, T15, T16, T17, T18, T19>(_ comp1: T1, _ comp2: T2, _ comp3: T3, _ comp4: T4, _ comp5: T5, _ comp6: T6, _ comp7: T7, _ comp8: T8, _ comp9: T9, _ comp10: T10, _ comp11: T11, _ comp12: T12, _ comp13: T13, _ comp14: T14, _ comp15: T15, _ comp16: T16, _ comp17: T17, _ comp18: T18, _ comp19: T19) -> [Component] {
    [Box(comp1), Box(comp2), Box(comp3), Box(comp4), Box(comp5), Box(comp6), Box(comp7), Box(comp8), Box(comp9), Box(comp10), Box(comp11), Box(comp12), Box(comp13), Box(comp14), Box(comp15), Box(comp16), Box(comp17), Box(comp18), Box(comp19)]
  }
  
  public static func buildBlock<T1, T2, T3, T4, T5, T6, T7, T8, T9, T10, T11, T12, T13, T14, T15, T16, T17, T18, T19, T20>(_ comp1: T1, _ comp2: T2, _ comp3: T3, _ comp4: T4, _ comp5: T5, _ comp6: T6, _ comp7: T7, _ comp8: T8, _ comp9: T9, _ comp10: T10, _ comp11: T11, _ comp12: T12, _ comp13: T13, _ comp14: T14, _ comp15: T15, _ comp16: T16, _ comp17: T17, _ comp18: T18, _ comp19: T19, _ comp20: T20) -> [Component] {
    [Box(comp1), Box(comp2), Box(comp3), Box(comp4), Box(comp5), Box(comp6), Box(comp7), Box(comp8), Box(comp9), Box(comp10), Box(comp11), Box(comp12), Box(comp13), Box(comp14), Box(comp15), Box(comp16), Box(comp17), Box(comp18), Box(comp19), Box(comp20)]
  }
}
