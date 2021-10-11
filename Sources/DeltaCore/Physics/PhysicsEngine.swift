import Foundation

open class PhysicsEngine {
	open class var clocksPerSecond: Double { 60 }
	open class var stepLength: Double { 1 / clocksPerSecond }
	open class var playerSpeed: Double { 4 }
  
	open var client: Client
  
	open var gameClock = CFAbsoluteTimeGetCurrent()
  
	public required init(client: Client) {
    self.client = client
  }
  
	open func update() {
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
  
	open func performStep() {
    if let player = client.server?.player {
      var position = player.position
      position.x += player.velocity.x / PhysicsEngine.clocksPerSecond
      position.y += player.velocity.y / PhysicsEngine.clocksPerSecond
      position.z += player.velocity.z / PhysicsEngine.clocksPerSecond
      
      client.server?.player.setPosition(to: position)
    }
  }
}
