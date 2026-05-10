import SpriteKit

struct PhysicsCategory: OptionSet {
    let rawValue: UInt32
    static let none   = PhysicsCategory(rawValue: 0)
    static let ball   = PhysicsCategory(rawValue: 1 << 0)
    static let player = PhysicsCategory(rawValue: 1 << 1)
    static let enemy  = PhysicsCategory(rawValue: 1 << 2)
    static let wall   = PhysicsCategory(rawValue: 1 << 3)
}

class Ball: SKNode {

    static let radius: CGFloat = 12
    private let bodyNode: SKShapeNode
    var thrownByTeam: CharacterTeam = .player
    var isActive: Bool = false

    override init() {
        let r = Ball.radius
        bodyNode = SKShapeNode(circleOfRadius: r)

        super.init()

        // Dark bandaged ball look
        bodyNode.fillColor = UIColor(red: 0.12, green: 0.08, blue: 0.15, alpha: 1.0)
        bodyNode.strokeColor = UIColor(red: 0.6, green: 0.4, blue: 0.7, alpha: 1.0)
        bodyNode.lineWidth = 2
        addChild(bodyNode)

        // Bandage wrapping lines
        drawBandageLines(r: r)

        // Creepy face on ball
        drawBallFace()

        setupPhysics(r: r)
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    private func drawBandageLines(r: CGFloat) {
        // Horizontal bandage strip
        let hStrip = SKShapeNode(rectOf: CGSize(width: r * 2, height: 4))
        hStrip.fillColor = UIColor(white: 0.9, alpha: 0.3)
        hStrip.strokeColor = UIColor(white: 0.7, alpha: 0.2)
        hStrip.lineWidth = 0.5
        bodyNode.addChild(hStrip)

        // Diagonal bandage strip
        let dStrip = SKShapeNode(rectOf: CGSize(width: r * 2, height: 3))
        dStrip.fillColor = UIColor(white: 0.9, alpha: 0.25)
        dStrip.strokeColor = UIColor(white: 0.7, alpha: 0.2)
        dStrip.lineWidth = 0.5
        dStrip.zRotation = CGFloat.pi / 4
        bodyNode.addChild(dStrip)
    }

    private func drawBallFace() {
        // Tiny dots for eyes
        for xPos: CGFloat in [-3.5, 3.5] {
            let eye = SKShapeNode(circleOfRadius: 1.5)
            eye.position = CGPoint(x: xPos, y: 2)
            eye.fillColor = UIColor(red: 0.9, green: 0.4, blue: 0.5, alpha: 0.9)
            eye.strokeColor = .clear
            bodyNode.addChild(eye)
        }

        // Tiny frown
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -3, y: -3))
        path.addCurve(to: CGPoint(x: 3, y: -3),
                      control1: CGPoint(x: -1, y: -5),
                      control2: CGPoint(x: 1, y: -5))
        let frown = SKShapeNode(path: path)
        frown.strokeColor = UIColor(red: 0.9, green: 0.4, blue: 0.5, alpha: 0.9)
        frown.lineWidth = 1
        frown.fillColor = .clear
        bodyNode.addChild(frown)
    }

    private func setupPhysics(r: CGFloat) {
        physicsBody = SKPhysicsBody(circleOfRadius: r)
        physicsBody?.isDynamic = true
        physicsBody?.affectedByGravity = false
        physicsBody?.restitution = 0.6
        physicsBody?.friction = 0.1
        physicsBody?.linearDamping = 0.5
        physicsBody?.allowsRotation = true
        physicsBody?.categoryBitMask = PhysicsCategory.ball.rawValue
        physicsBody?.contactTestBitMask = PhysicsCategory.player.rawValue | PhysicsCategory.enemy.rawValue
        physicsBody?.collisionBitMask = PhysicsCategory.wall.rawValue
    }

    func launch(toward target: CGPoint, from origin: CGPoint, speed: CGFloat = 420) {
        isActive = true
        let dx = target.x - origin.x
        let dy = target.y - origin.y
        let length = hypot(dx, dy)
        guard length > 0 else { return }

        let vx = (dx / length) * speed
        let vy = (dy / length) * speed
        physicsBody?.velocity = CGVector(dx: vx, dy: vy)

        // Spin
        physicsBody?.angularVelocity = (thrownByTeam == .player) ? 8 : -8

        // Trail effect via periodic emitter actions
        startTrail()

        // Deactivate after 2.5 seconds so it can be picked up
        run(SKAction.sequence([
            SKAction.wait(forDuration: 2.5),
            SKAction.run { [weak self] in
                self?.deactivate()
            }
        ]), withKey: "deactivate")
    }

    private func startTrail() {
        let trail = SKAction.repeatForever(SKAction.sequence([
            SKAction.run { [weak self] in
                guard let self = self, let parent = self.parent else { return }
                let ghost = SKShapeNode(circleOfRadius: Ball.radius * 0.6)
                ghost.fillColor = UIColor(red: 0.8, green: 0.3, blue: 0.9, alpha: 0.3)
                ghost.strokeColor = .clear
                ghost.position = self.position
                ghost.zPosition = self.zPosition - 1
                parent.addChild(ghost)
                ghost.run(SKAction.sequence([
                    SKAction.group([
                        SKAction.scale(to: 0.1, duration: 0.15),
                        SKAction.fadeOut(withDuration: 0.15)
                    ]),
                    SKAction.removeFromParent()
                ]))
            },
            SKAction.wait(forDuration: 0.04)
        ]))
        run(trail, withKey: "trail")
    }

    func deactivate() {
        isActive = false
        physicsBody?.velocity = .zero
        physicsBody?.angularVelocity = 0
        removeAction(forKey: "trail")
        removeAction(forKey: "deactivate")

        // Gentle pulse to show it's pickupable
        let pulse = SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.12, duration: 0.4),
            SKAction.scale(to: 1.0, duration: 0.4)
        ]))
        bodyNode.run(pulse, withKey: "pulse")
    }

    func resetBall(at position: CGPoint) {
        self.position = position
        isActive = false
        physicsBody?.velocity = .zero
        physicsBody?.angularVelocity = 0
        removeAllActions()
        bodyNode.removeAllActions()
        bodyNode.setScale(1.0)
    }
}
