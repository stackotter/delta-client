import Foundation

class PhysicsEngine {
  static var clocksPerSecond: Double = 60
  static var stepLength: Double = 1 / clocksPerSecond
  static var playerSpeed: Double = 4
  
  var client: Client
  
  var gameClock = CFAbsoluteTimeGetCurrent()
  
  init(client: Client) {
    self.client = client
  }
  
  func update() {
    // calculate time since last update
    let currentTime = CFAbsoluteTimeGetCurrent()
    let deltaTime = currentTime - gameClock
    if deltaTime <= 0 {
      // that must've been a very quick frame
      return
    }
    
    // calculate how many steps need to be done
    let numSteps = Int((deltaTime / PhysicsEngine.stepLength).rounded())
    
    // perform simulation steps
    for _ in 0..<numSteps {
      performStep()
    }
    
    // update game clock
    gameClock += Double(numSteps) * PhysicsEngine.stepLength
  }
  
  func performStep() {
    var position = client.game.player.position
    position.x += client.game.player.velocity.x / PhysicsEngine.clocksPerSecond
    position.y += client.game.player.velocity.y / PhysicsEngine.clocksPerSecond
    position.z += client.game.player.velocity.z / PhysicsEngine.clocksPerSecond
    
    client.game.player.setPosition(to: position)
  }
}
