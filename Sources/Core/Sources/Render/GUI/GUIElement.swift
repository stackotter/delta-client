struct GUIElement {
  var content: Content
  var constraints: Constraints

  init(_ content: Content, _ constraints: Constraints) {
    self.content = content
    self.constraints = constraints
  }

  init(_ content: Content, _ vertical: VerticalConstraint, _ horizontal: HorizontalConstraint) {
    self.content = content
    self.constraints = Constraints(vertical, horizontal)
  }
}
