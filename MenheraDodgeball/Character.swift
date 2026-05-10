import SpriteKit

enum CharacterState {
    case idle, moving, throwing, hit, out
}

enum CharacterTeam {
    case player, enemy
}

class Character: SKNode {

    let team: CharacterTeam
    var state: CharacterState = .idle
    var isAlive: Bool = true
    var hasBall: Bool = false

    private let bodyNode: SKShapeNode
    private let faceNode: SKNode
    private var leftEye: SKShapeNode!
    private var rightEye: SKShapeNode!
    private var mouth: SKShapeNode!
    private var bandage: SKShapeNode!
    private var tearLeft: SKShapeNode?
    private var tearRight: SKShapeNode?

    static let radius: CGFloat = 22

    init(team: CharacterTeam) {
        self.team = team

        // Body
        let r = Character.radius
        bodyNode = SKShapeNode(circleOfRadius: r)
        bodyNode.lineWidth = 2

        faceNode = SKNode()

        super.init()

        setupBody()
        setupFace()
        setupPhysics()
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    private func setupBody() {
        let r = Character.radius
        if team == .player {
            bodyNode.fillColor = UIColor(red: 1.0, green: 0.75, blue: 0.85, alpha: 1.0) // pale pink
            bodyNode.strokeColor = UIColor(red: 0.9, green: 0.5, blue: 0.7, alpha: 1.0)
        } else {
            bodyNode.fillColor = UIColor(red: 0.35, green: 0.2, blue: 0.45, alpha: 1.0) // dark purple
            bodyNode.strokeColor = UIColor(red: 0.6, green: 0.3, blue: 0.7, alpha: 1.0)
        }
        bodyNode.lineWidth = 2
        addChild(bodyNode)

        // Shadow
        let shadow = SKShapeNode(ellipseOf: CGSize(width: r * 1.8, height: r * 0.5))
        shadow.fillColor = UIColor(white: 0, alpha: 0.25)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -r - 4)
        shadow.zPosition = -1
        addChild(shadow)

        addChild(faceNode)
    }

    private func setupFace() {
        drawIdleFace()
    }

    private func clearFace() {
        faceNode.removeAllChildren()
    }

    private func drawIdleFace() {
        clearFace()

        // Eyes: teary dots
        leftEye = makeEye(x: -7, y: 4)
        rightEye = makeEye(x: 7, y: 4)
        faceNode.addChild(leftEye)
        faceNode.addChild(rightEye)

        // Mouth: small wavy line
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -6, y: -6))
        path.addCurve(to: CGPoint(x: 6, y: -6),
                      control1: CGPoint(x: -2, y: -9),
                      control2: CGPoint(x: 2, y: -3))
        mouth = SKShapeNode(path: path)
        mouth.strokeColor = team == .player ?
            UIColor(red: 0.8, green: 0.3, blue: 0.5, alpha: 1) :
            UIColor(red: 0.8, green: 0.6, blue: 0.9, alpha: 1)
        mouth.lineWidth = 1.5
        mouth.fillColor = .clear
        faceNode.addChild(mouth)

        // Bandage on forehead
        drawBandage()

        // Dark circles under eyes
        let dcLeft = makeUnderEye(x: -7, y: 1)
        let dcRight = makeUnderEye(x: 7, y: 1)
        faceNode.addChild(dcLeft)
        faceNode.addChild(dcRight)
    }

    private func makeEye(x: CGFloat, y: CGFloat) -> SKShapeNode {
        let eye = SKShapeNode(circleOfRadius: 2.5)
        eye.position = CGPoint(x: x, y: y)
        eye.fillColor = team == .player ?
            UIColor(red: 0.6, green: 0.2, blue: 0.4, alpha: 1) :
            UIColor(red: 0.85, green: 0.7, blue: 0.95, alpha: 1)
        eye.strokeColor = .clear
        // Shine dot
        let shine = SKShapeNode(circleOfRadius: 0.8)
        shine.fillColor = .white
        shine.strokeColor = .clear
        shine.position = CGPoint(x: 1, y: 1)
        eye.addChild(shine)
        return eye
    }

    private func makeUnderEye(x: CGFloat, y: CGFloat) -> SKShapeNode {
        let dc = SKShapeNode(ellipseOf: CGSize(width: 7, height: 2))
        dc.position = CGPoint(x: x, y: y)
        dc.fillColor = UIColor(red: 0.5, green: 0.3, blue: 0.6, alpha: 0.4)
        dc.strokeColor = .clear
        return dc
    }

    private func drawBandage() {
        let bnd = SKShapeNode(rectOf: CGSize(width: 12, height: 5), cornerRadius: 2)
        bnd.position = CGPoint(x: 2, y: 14)
        bnd.fillColor = UIColor(white: 0.95, alpha: 0.9)
        bnd.strokeColor = UIColor(white: 0.7, alpha: 1)
        bnd.lineWidth = 0.5
        bnd.zRotation = 0.15

        // Cross lines on bandage
        let h = SKShapeNode(rectOf: CGSize(width: 8, height: 1))
        h.fillColor = UIColor(red: 0.9, green: 0.5, blue: 0.6, alpha: 0.8)
        h.strokeColor = .clear
        bnd.addChild(h)

        let v = SKShapeNode(rectOf: CGSize(width: 1, height: 3))
        v.fillColor = UIColor(red: 0.9, green: 0.5, blue: 0.6, alpha: 0.8)
        v.strokeColor = .clear
        bnd.addChild(v)

        bandage = bnd
        faceNode.addChild(bnd)
    }

    private func drawHitFace() {
        clearFace()

        // X eyes
        let xEyeLeft = makeXEye(x: -7, y: 4)
        let xEyeRight = makeXEye(x: 7, y: 4)
        faceNode.addChild(xEyeLeft)
        faceNode.addChild(xEyeRight)

        // Jagged distressed mouth
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -7, y: -5))
        path.addLine(to: CGPoint(x: -3, y: -9))
        path.addLine(to: CGPoint(x: 0, y: -6))
        path.addLine(to: CGPoint(x: 3, y: -10))
        path.addLine(to: CGPoint(x: 7, y: -5))
        let m = SKShapeNode(path: path)
        m.strokeColor = UIColor(red: 0.9, green: 0.3, blue: 0.4, alpha: 1)
        m.lineWidth = 1.5
        m.fillColor = .clear
        faceNode.addChild(m)

        // Tears
        spawnTears()
    }

    private func makeXEye(x: CGFloat, y: CGFloat) -> SKNode {
        let container = SKNode()
        container.position = CGPoint(x: x, y: y)

        let line1 = SKShapeNode()
        let p1 = CGMutablePath()
        p1.move(to: CGPoint(x: -3, y: -3))
        p1.addLine(to: CGPoint(x: 3, y: 3))
        line1.path = p1
        line1.strokeColor = UIColor(red: 0.8, green: 0.2, blue: 0.3, alpha: 1)
        line1.lineWidth = 2
        container.addChild(line1)

        let line2 = SKShapeNode()
        let p2 = CGMutablePath()
        p2.move(to: CGPoint(x: 3, y: -3))
        p2.addLine(to: CGPoint(x: -3, y: 3))
        line2.path = p2
        line2.strokeColor = UIColor(red: 0.8, green: 0.2, blue: 0.3, alpha: 1)
        line2.lineWidth = 2
        container.addChild(line2)

        return container
    }

    private func spawnTears() {
        for xPos: CGFloat in [-7, 7] {
            let tear = SKShapeNode(ellipseOf: CGSize(width: 4, height: 6))
            tear.position = CGPoint(x: xPos, y: -2)
            tear.fillColor = UIColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 0.8)
            tear.strokeColor = .clear
            faceNode.addChild(tear)

            let fall = SKAction.sequence([
                SKAction.moveBy(x: 0, y: -10, duration: 0.3),
                SKAction.fadeOut(withDuration: 0.2),
                SKAction.removeFromParent()
            ])
            tear.run(fall)
        }
    }

    private func setupPhysics() {
        let r = Character.radius
        physicsBody = SKPhysicsBody(circleOfRadius: r)
        physicsBody?.isDynamic = true
        physicsBody?.affectedByGravity = false
        physicsBody?.allowsRotation = false
        physicsBody?.restitution = 0.3
        physicsBody?.friction = 0.8
        physicsBody?.linearDamping = 8.0

        let cat: PhysicsCategory = (team == .player) ? .player : .enemy
        physicsBody?.categoryBitMask = cat.rawValue
        physicsBody?.contactTestBitMask = PhysicsCategory.ball.rawValue
        physicsBody?.collisionBitMask = PhysicsCategory.wall.rawValue | cat.rawValue
    }

    // MARK: - State Changes

    func setMoving(to destination: CGPoint) {
        guard isAlive, state != .out else { return }
        state = .moving
        let dist = hypot(destination.x - position.x, destination.y - position.y)
        let duration = TimeInterval(dist / 160.0)
        let move = SKAction.move(to: destination, duration: duration)
        move.timingMode = .easeInEaseOut
        run(SKAction.sequence([move, SKAction.run {
            if self.state == .moving { self.state = .idle }
        }]), withKey: "move")
    }

    func throwBall() {
        guard isAlive, hasBall else { return }
        hasBall = false
        state = .throwing

        // Throw animation: quick lunge forward then back
        let dir: CGFloat = (team == .player) ? 1 : -1
        let lunge = SKAction.moveBy(x: 10 * dir, y: 0, duration: 0.08)
        let back = SKAction.moveBy(x: -10 * dir, y: 0, duration: 0.12)
        run(SKAction.sequence([lunge, back])) {
            self.state = .idle
        }

        // Throw dialogue bubble
        showSpeechBubble(Dialogues.randomThrow())
    }

    func getHit() {
        guard isAlive else { return }
        isAlive = false
        state = .hit
        drawHitFace()

        // Flash red
        bodyNode.run(SKAction.sequence([
            SKAction.colorize(with: .red, colorBlendFactor: 0.8, duration: 0.05),
            SKAction.colorize(with: .clear, colorBlendFactor: 0, duration: 0.15)
        ]))

        // Screen shake via position wobble
        let shake = SKAction.sequence([
            SKAction.moveBy(x: -6, y: 2, duration: 0.04),
            SKAction.moveBy(x: 12, y: -4, duration: 0.04),
            SKAction.moveBy(x: -8, y: 3, duration: 0.04),
            SKAction.moveBy(x: 6, y: -2, duration: 0.04),
            SKAction.moveBy(x: -4, y: 1, duration: 0.04)
        ])

        // Collapse animation
        let collapse = SKAction.sequence([
            shake,
            SKAction.group([
                SKAction.scale(to: 0.7, duration: 0.3),
                SKAction.rotate(toAngle: team == .player ? -CGFloat.pi / 2 : CGFloat.pi / 2, duration: 0.3),
                SKAction.fadeAlpha(to: 0.5, duration: 0.3)
            ]),
            SKAction.run { [weak self] in
                self?.state = .out
                self?.physicsBody?.categoryBitMask = 0
                self?.physicsBody?.contactTestBitMask = 0
                self?.physicsBody?.collisionBitMask = 0
            }
        ])
        run(collapse)

        // Hit dialogue
        showSpeechBubble(Dialogues.random(.gotHit))

        // Spawn broken heart particles
        spawnHearts()
    }

    private func spawnHearts() {
        for i in 0..<5 {
            let heart = SKLabelNode(text: "💔")
            heart.fontSize = 10 + CGFloat(i) * 2
            heart.position = CGPoint(x: CGFloat.random(in: -15...15),
                                     y: CGFloat.random(in: -10...10))
            heart.zPosition = 10
            addChild(heart)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let dist = CGFloat.random(in: 30...60)
            heart.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: cos(angle) * dist, y: sin(angle) * dist, duration: 0.6),
                    SKAction.fadeOut(withDuration: 0.6),
                    SKAction.rotate(byAngle: CGFloat.random(in: -2...2), duration: 0.6)
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }

    func pickUpBall() {
        hasBall = true
        // Small bounce animation to show pickup
        let bounce = SKAction.sequence([
            SKAction.scale(to: 1.15, duration: 0.08),
            SKAction.scale(to: 1.0, duration: 0.08)
        ])
        run(bounce)

        // Pickup dialogue (only sometimes to avoid spam)
        if Bool.random() {
            showSpeechBubble(Dialogues.random(.pickup))
        }
    }

    // MARK: - Speech Bubble

    func showSpeechBubble(_ text: String) {
        // Remove any existing bubble first
        childNode(withName: "speechBubble")?.removeFromParent()

        let label = SKLabelNode(text: text)
        label.fontName = "HiraMaruProN-W4"
        label.fontSize = 11
        label.fontColor = UIColor(red: 1, green: 0.85, blue: 0.95, alpha: 1)
        label.horizontalAlignmentMode = .center

        // Bubble background sized to text
        let padding: CGFloat = 8
        let bubbleWidth = max(label.frame.width + padding * 2, 60)
        let bubbleHeight: CGFloat = 22
        let bubble = SKShapeNode(rectOf: CGSize(width: bubbleWidth, height: bubbleHeight), cornerRadius: 8)
        bubble.fillColor = UIColor(red: 0.15, green: 0.1, blue: 0.25, alpha: 0.88)
        bubble.strokeColor = UIColor(red: 1, green: 0.6, blue: 0.8, alpha: 0.7)
        bubble.lineWidth = 1
        bubble.name = "speechBubble"
        bubble.position = CGPoint(x: 0, y: Character.radius + 18)
        bubble.zPosition = 15

        label.verticalAlignmentMode = .center
        bubble.addChild(label)
        addChild(bubble)

        bubble.run(SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: 0, y: 18, duration: 1.0),
                SKAction.sequence([
                    SKAction.wait(forDuration: 0.6),
                    SKAction.fadeOut(withDuration: 0.4)
                ])
            ]),
            SKAction.removeFromParent()
        ]))
    }
}
