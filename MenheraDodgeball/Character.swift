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

    private let bodyContainer: SKNode
    private let faceNode: SKNode
    private let hairNode: SKNode
    private let accessoryNode: SKNode
    private var bodyCircle: SKShapeNode!
    let characterIndex: Int

    static let radius: CGFloat = 24

    // Each character has unique look
    struct CharacterStyle {
        let bodyColor: UIColor
        let strokeColor: UIColor
        let hairColor: UIColor
        let hairStyle: Int        // 0=twintail, 1=bob, 2=long
        let eyeColor: UIColor
        let accessoryColor: UIColor
        let blushColor: UIColor
    }

    static let playerStyles: [CharacterStyle] = [
        // Menhera-chan: pink, twintails
        CharacterStyle(
            bodyColor: UIColor(red: 1.0, green: 0.88, blue: 0.92, alpha: 1.0),
            strokeColor: UIColor(red: 0.95, green: 0.6, blue: 0.75, alpha: 1.0),
            hairColor: UIColor(red: 1.0, green: 0.65, blue: 0.78, alpha: 1.0),
            hairStyle: 0,
            eyeColor: UIColor(red: 0.85, green: 0.2, blue: 0.45, alpha: 1.0),
            accessoryColor: UIColor(red: 1.0, green: 0.4, blue: 0.6, alpha: 1.0),
            blushColor: UIColor(red: 1.0, green: 0.6, blue: 0.7, alpha: 0.5)
        ),
        // Yami-chan: dark purple, bob
        CharacterStyle(
            bodyColor: UIColor(red: 0.92, green: 0.85, blue: 0.95, alpha: 1.0),
            strokeColor: UIColor(red: 0.6, green: 0.35, blue: 0.7, alpha: 1.0),
            hairColor: UIColor(red: 0.35, green: 0.15, blue: 0.5, alpha: 1.0),
            hairStyle: 1,
            eyeColor: UIColor(red: 0.5, green: 0.2, blue: 0.7, alpha: 1.0),
            accessoryColor: UIColor(red: 0.7, green: 0.4, blue: 0.9, alpha: 1.0),
            blushColor: UIColor(red: 0.8, green: 0.6, blue: 0.9, alpha: 0.4)
        ),
        // Tsundere-chan: red/orange, long hair
        CharacterStyle(
            bodyColor: UIColor(red: 1.0, green: 0.9, blue: 0.88, alpha: 1.0),
            strokeColor: UIColor(red: 0.9, green: 0.45, blue: 0.35, alpha: 1.0),
            hairColor: UIColor(red: 0.95, green: 0.5, blue: 0.3, alpha: 1.0),
            hairStyle: 2,
            eyeColor: UIColor(red: 0.9, green: 0.35, blue: 0.2, alpha: 1.0),
            accessoryColor: UIColor(red: 1.0, green: 0.6, blue: 0.3, alpha: 1.0),
            blushColor: UIColor(red: 1.0, green: 0.5, blue: 0.4, alpha: 0.5)
        ),
    ]

    static let enemyStyles: [CharacterStyle] = [
        // Psycho-chan: black/red
        CharacterStyle(
            bodyColor: UIColor(red: 0.9, green: 0.85, blue: 0.88, alpha: 1.0),
            strokeColor: UIColor(red: 0.7, green: 0.15, blue: 0.25, alpha: 1.0),
            hairColor: UIColor(red: 0.15, green: 0.08, blue: 0.12, alpha: 1.0),
            hairStyle: 2,
            eyeColor: UIColor(red: 0.9, green: 0.1, blue: 0.2, alpha: 1.0),
            accessoryColor: UIColor(red: 0.85, green: 0.1, blue: 0.15, alpha: 1.0),
            blushColor: UIColor(red: 0.9, green: 0.3, blue: 0.4, alpha: 0.4)
        ),
        // Namida-chan: blue/teal
        CharacterStyle(
            bodyColor: UIColor(red: 0.88, green: 0.9, blue: 0.95, alpha: 1.0),
            strokeColor: UIColor(red: 0.3, green: 0.5, blue: 0.7, alpha: 1.0),
            hairColor: UIColor(red: 0.3, green: 0.45, blue: 0.7, alpha: 1.0),
            hairStyle: 0,
            eyeColor: UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0),
            accessoryColor: UIColor(red: 0.4, green: 0.6, blue: 0.9, alpha: 1.0),
            blushColor: UIColor(red: 0.6, green: 0.7, blue: 0.9, alpha: 0.4)
        ),
        // Stitch-chan: green/black goth
        CharacterStyle(
            bodyColor: UIColor(red: 0.88, green: 0.92, blue: 0.88, alpha: 1.0),
            strokeColor: UIColor(red: 0.2, green: 0.5, blue: 0.3, alpha: 1.0),
            hairColor: UIColor(red: 0.12, green: 0.18, blue: 0.12, alpha: 1.0),
            hairStyle: 1,
            eyeColor: UIColor(red: 0.3, green: 0.7, blue: 0.4, alpha: 1.0),
            accessoryColor: UIColor(red: 0.4, green: 0.8, blue: 0.5, alpha: 1.0),
            blushColor: UIColor(red: 0.5, green: 0.8, blue: 0.6, alpha: 0.3)
        ),
    ]

    init(team: CharacterTeam, index: Int = -1) {
        self.team = team
        self.characterIndex = index >= 0 ? index : Int.random(in: 0...2)

        bodyContainer = SKNode()
        faceNode = SKNode()
        hairNode = SKNode()
        accessoryNode = SKNode()

        super.init()

        let style = self.style
        setupBody(style: style)
        setupHair(style: style)
        setupFace(style: style)
        setupAccessories(style: style)
        setupShadow()
        setupPhysics()
        startIdleAnimation()
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    var style: CharacterStyle {
        let styles = team == .player ? Character.playerStyles : Character.enemyStyles
        return styles[min(characterIndex, styles.count - 1)]
    }

    // MARK: - Body

    private func setupBody(style: CharacterStyle) {
        let r = Character.radius

        // Body outline glow
        let glow = SKShapeNode(circleOfRadius: r + 3)
        glow.fillColor = style.strokeColor.withAlphaComponent(0.15)
        glow.strokeColor = .clear
        glow.zPosition = -1
        bodyContainer.addChild(glow)

        // Main body
        bodyCircle = SKShapeNode(circleOfRadius: r)
        bodyCircle.fillColor = style.bodyColor
        bodyCircle.strokeColor = style.strokeColor
        bodyCircle.lineWidth = 2.5
        bodyCircle.zPosition = 0
        bodyContainer.addChild(bodyCircle)

        // Cheek blush
        for xPos: CGFloat in [-10, 10] {
            let blush = SKShapeNode(ellipseOf: CGSize(width: 10, height: 6))
            blush.position = CGPoint(x: xPos, y: -2)
            blush.fillColor = style.blushColor
            blush.strokeColor = .clear
            blush.zPosition = 2
            bodyContainer.addChild(blush)
        }

        bodyContainer.addChild(faceNode)
        bodyContainer.addChild(hairNode)
        bodyContainer.addChild(accessoryNode)
        addChild(bodyContainer)
    }

    // MARK: - Hair

    private func setupHair(style: CharacterStyle) {
        hairNode.removeAllChildren()
        let r = Character.radius

        switch style.hairStyle {
        case 0: // Twintails
            // Top hair dome
            let topHair = SKShapeNode(circleOfRadius: r + 2)
            topHair.fillColor = style.hairColor
            topHair.strokeColor = style.hairColor.adjusted(brightness: -0.15)
            topHair.lineWidth = 1
            topHair.zPosition = -0.5

            let topMask = SKCropNode()
            let maskRect = SKShapeNode(rectOf: CGSize(width: r * 3, height: r * 1.5))
            maskRect.fillColor = .white
            maskRect.position = CGPoint(x: 0, y: r * 0.4)
            topMask.maskNode = maskRect
            topMask.addChild(topHair)
            hairNode.addChild(topMask)

            // Twintails
            for side: CGFloat in [-1, 1] {
                let tail = SKShapeNode(ellipseOf: CGSize(width: 14, height: 28))
                tail.position = CGPoint(x: side * (r + 4), y: 2)
                tail.fillColor = style.hairColor
                tail.strokeColor = style.hairColor.adjusted(brightness: -0.15)
                tail.lineWidth = 1
                tail.zPosition = -0.5
                tail.zRotation = side * 0.2
                hairNode.addChild(tail)

                // Hair tie ribbon
                let ribbon = SKShapeNode(circleOfRadius: 4)
                ribbon.position = CGPoint(x: side * (r + 2), y: 14)
                ribbon.fillColor = style.accessoryColor
                ribbon.strokeColor = style.accessoryColor.adjusted(brightness: -0.2)
                ribbon.lineWidth = 1
                ribbon.zPosition = 3
                hairNode.addChild(ribbon)
            }

            // Bangs
            drawBangs(style: style, r: r)

        case 1: // Bob cut
            // Hair dome
            let dome = SKShapeNode(circleOfRadius: r + 4)
            dome.fillColor = style.hairColor
            dome.strokeColor = style.hairColor.adjusted(brightness: -0.15)
            dome.lineWidth = 1
            dome.zPosition = -0.5

            let domeMask = SKCropNode()
            let mask = SKShapeNode(rectOf: CGSize(width: r * 3, height: r * 2.2))
            mask.fillColor = .white
            mask.position = CGPoint(x: 0, y: r * 0.15)
            domeMask.maskNode = mask
            domeMask.addChild(dome)
            hairNode.addChild(domeMask)

            // Side hair
            for side: CGFloat in [-1, 1] {
                let sideHair = SKShapeNode(rectOf: CGSize(width: 10, height: 18), cornerRadius: 4)
                sideHair.position = CGPoint(x: side * (r + 1), y: -4)
                sideHair.fillColor = style.hairColor
                sideHair.strokeColor = .clear
                sideHair.zPosition = -0.5
                hairNode.addChild(sideHair)
            }

            drawBangs(style: style, r: r)

        default: // Long hair
            // Top dome
            let dome = SKShapeNode(circleOfRadius: r + 3)
            dome.fillColor = style.hairColor
            dome.strokeColor = style.hairColor.adjusted(brightness: -0.15)
            dome.lineWidth = 1
            dome.zPosition = -0.5

            let domeMask = SKCropNode()
            let mask = SKShapeNode(rectOf: CGSize(width: r * 3, height: r * 1.8))
            mask.fillColor = .white
            mask.position = CGPoint(x: 0, y: r * 0.3)
            domeMask.maskNode = mask
            domeMask.addChild(dome)
            hairNode.addChild(domeMask)

            // Long side strands
            for side: CGFloat in [-1, 1] {
                let strand = SKShapeNode(rectOf: CGSize(width: 12, height: 32), cornerRadius: 5)
                strand.position = CGPoint(x: side * (r + 2), y: -10)
                strand.fillColor = style.hairColor
                strand.strokeColor = .clear
                strand.zPosition = -0.5
                strand.zRotation = side * 0.08
                hairNode.addChild(strand)
            }

            drawBangs(style: style, r: r)
        }
    }

    private func drawBangs(style: CharacterStyle, r: CGFloat) {
        let bangPath = CGMutablePath()
        bangPath.move(to: CGPoint(x: -r * 0.85, y: r * 0.5))
        bangPath.addCurve(to: CGPoint(x: 0, y: r * 0.35),
                          control1: CGPoint(x: -r * 0.5, y: r * 0.9),
                          control2: CGPoint(x: -r * 0.2, y: r * 0.7))
        bangPath.addCurve(to: CGPoint(x: r * 0.85, y: r * 0.5),
                          control1: CGPoint(x: r * 0.2, y: r * 0.7),
                          control2: CGPoint(x: r * 0.5, y: r * 0.9))
        let bangs = SKShapeNode(path: bangPath)
        bangs.fillColor = style.hairColor
        bangs.strokeColor = style.hairColor.adjusted(brightness: -0.1)
        bangs.lineWidth = 1
        bangs.zPosition = 3
        hairNode.addChild(bangs)
    }

    // MARK: - Face

    private func setupFace(style: CharacterStyle) {
        drawIdleFace(style: style)
    }

    private func clearFace() {
        faceNode.removeAllChildren()
    }

    private func drawIdleFace(style: CharacterStyle) {
        clearFace()

        // Eyes - big anime style
        for (xPos, side) in [(-8.0, -1.0), (8.0, 1.0)] as [(CGFloat, CGFloat)] {
            drawAnimeEye(at: CGPoint(x: xPos, y: 4), color: style.eyeColor, side: side)
        }

        // Mouth - small cat mouth
        let mouthPath = CGMutablePath()
        mouthPath.move(to: CGPoint(x: -4, y: -7))
        mouthPath.addCurve(to: CGPoint(x: 0, y: -5),
                           control1: CGPoint(x: -2, y: -9),
                           control2: CGPoint(x: -1, y: -5))
        mouthPath.addCurve(to: CGPoint(x: 4, y: -7),
                           control1: CGPoint(x: 1, y: -5),
                           control2: CGPoint(x: 2, y: -9))
        let mouth = SKShapeNode(path: mouthPath)
        mouth.strokeColor = style.eyeColor.withAlphaComponent(0.7)
        mouth.lineWidth = 1.5
        mouth.fillColor = .clear
        mouth.zPosition = 4
        faceNode.addChild(mouth)

        // Bandage
        drawBandage(style: style)
    }

    private func drawAnimeEye(at pos: CGPoint, color: UIColor, side: CGFloat) {
        // Eye white
        let eyeWhite = SKShapeNode(ellipseOf: CGSize(width: 10, height: 11))
        eyeWhite.position = pos
        eyeWhite.fillColor = .white
        eyeWhite.strokeColor = color.withAlphaComponent(0.3)
        eyeWhite.lineWidth = 1
        eyeWhite.zPosition = 3

        // Iris
        let iris = SKShapeNode(circleOfRadius: 4)
        iris.fillColor = color
        iris.strokeColor = color.adjusted(brightness: -0.3)
        iris.lineWidth = 0.5
        iris.zPosition = 1

        // Pupil
        let pupil = SKShapeNode(circleOfRadius: 2)
        pupil.fillColor = UIColor(white: 0.05, alpha: 1)
        pupil.strokeColor = .clear
        pupil.zPosition = 2
        iris.addChild(pupil)

        // Big shine
        let shine1 = SKShapeNode(circleOfRadius: 1.8)
        shine1.position = CGPoint(x: side * 1.5, y: 1.5)
        shine1.fillColor = .white
        shine1.strokeColor = .clear
        shine1.zPosition = 3
        iris.addChild(shine1)

        // Small shine
        let shine2 = SKShapeNode(circleOfRadius: 0.8)
        shine2.position = CGPoint(x: side * -1, y: -1.5)
        shine2.fillColor = UIColor(white: 1, alpha: 0.7)
        shine2.strokeColor = .clear
        shine2.zPosition = 3
        iris.addChild(shine2)

        eyeWhite.addChild(iris)
        faceNode.addChild(eyeWhite)
    }

    private func drawBandage(style: CharacterStyle) {
        let bnd = SKShapeNode(rectOf: CGSize(width: 13, height: 6), cornerRadius: 2)
        bnd.position = CGPoint(x: 3, y: Character.radius - 4)
        bnd.fillColor = UIColor(white: 0.97, alpha: 0.95)
        bnd.strokeColor = UIColor(white: 0.8, alpha: 1)
        bnd.lineWidth = 0.5
        bnd.zRotation = 0.2
        bnd.zPosition = 4

        let cross1 = SKShapeNode(rectOf: CGSize(width: 8, height: 1.2))
        cross1.fillColor = style.accessoryColor.withAlphaComponent(0.7)
        cross1.strokeColor = .clear
        bnd.addChild(cross1)

        let cross2 = SKShapeNode(rectOf: CGSize(width: 1.2, height: 4))
        cross2.fillColor = style.accessoryColor.withAlphaComponent(0.7)
        cross2.strokeColor = .clear
        bnd.addChild(cross2)

        faceNode.addChild(bnd)
    }

    // MARK: - Accessories

    private func setupAccessories(style: CharacterStyle) {
        accessoryNode.removeAllChildren()

        // Under-eye dark circles (menhera signature)
        for x: CGFloat in [-8, 8] {
            let dc = SKShapeNode(ellipseOf: CGSize(width: 8, height: 2.5))
            dc.position = CGPoint(x: x, y: 0)
            dc.fillColor = UIColor(red: 0.5, green: 0.3, blue: 0.6, alpha: 0.35)
            dc.strokeColor = .clear
            dc.zPosition = 4
            accessoryNode.addChild(dc)
        }
    }

    private func setupShadow() {
        let r = Character.radius
        let shadow = SKShapeNode(ellipseOf: CGSize(width: r * 2.0, height: r * 0.55))
        shadow.fillColor = UIColor(white: 0, alpha: 0.2)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 0, y: -r - 5)
        shadow.zPosition = -2
        addChild(shadow)
    }

    // MARK: - Hit Face

    private func drawHitFace() {
        clearFace()
        let style = self.style

        // X eyes
        for xPos: CGFloat in [-8, 8] {
            let container = SKNode()
            container.position = CGPoint(x: xPos, y: 4)
            container.zPosition = 4

            for angle: CGFloat in [.pi / 4, -.pi / 4] {
                let line = SKShapeNode(rectOf: CGSize(width: 2, height: 10))
                line.fillColor = UIColor(red: 0.8, green: 0.15, blue: 0.25, alpha: 1)
                line.strokeColor = .clear
                line.zRotation = angle
                container.addChild(line)
            }
            faceNode.addChild(container)
        }

        // Wavy distressed mouth
        let mPath = CGMutablePath()
        mPath.move(to: CGPoint(x: -8, y: -6))
        mPath.addLine(to: CGPoint(x: -4, y: -10))
        mPath.addLine(to: CGPoint(x: 0, y: -7))
        mPath.addLine(to: CGPoint(x: 4, y: -11))
        mPath.addLine(to: CGPoint(x: 8, y: -6))
        let mouth = SKShapeNode(path: mPath)
        mouth.strokeColor = UIColor(red: 0.85, green: 0.2, blue: 0.35, alpha: 1)
        mouth.lineWidth = 1.8
        mouth.fillColor = .clear
        mouth.zPosition = 4
        faceNode.addChild(mouth)

        // Tears
        spawnTears(style: style)
    }

    private func spawnTears(style: CharacterStyle) {
        for xPos: CGFloat in [-8, 8] {
            let tear = SKShapeNode(ellipseOf: CGSize(width: 5, height: 8))
            tear.position = CGPoint(x: xPos, y: -3)
            tear.fillColor = UIColor(red: 0.55, green: 0.75, blue: 1.0, alpha: 0.8)
            tear.strokeColor = UIColor(red: 0.4, green: 0.6, blue: 0.9, alpha: 0.5)
            tear.lineWidth = 0.5
            tear.zPosition = 5
            faceNode.addChild(tear)

            tear.run(SKAction.sequence([
                SKAction.moveBy(x: 0, y: -14, duration: 0.35),
                SKAction.fadeOut(withDuration: 0.15),
                SKAction.removeFromParent()
            ]))
        }
    }

    // MARK: - Idle Animation

    private func startIdleAnimation() {
        // Gentle breathing
        let breathe = SKAction.repeatForever(SKAction.sequence([
            SKAction.scaleY(to: 1.03, duration: 0.8),
            SKAction.scaleY(to: 1.0, duration: 0.8)
        ]))
        bodyContainer.run(breathe, withKey: "breathe")

        // Occasional blink
        let blink = SKAction.repeatForever(SKAction.sequence([
            SKAction.wait(forDuration: TimeInterval.random(in: 2.5...5.0)),
            SKAction.run { [weak self] in self?.doBlink() },
            SKAction.wait(forDuration: 0.15),
            SKAction.run { [weak self] in
                guard let self = self, self.isAlive else { return }
                self.drawIdleFace(style: self.style)
            }
        ]))
        run(blink, withKey: "blink")
    }

    private func doBlink() {
        faceNode.children.filter { $0 is SKShapeNode }.forEach { node in
            if let shape = node as? SKShapeNode, shape.fillColor == .white {
                shape.yScale = 0.1
            }
        }
    }

    // MARK: - Physics

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
        let duration = TimeInterval(dist / 170.0)
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

        let dir: CGFloat = (team == .player) ? 1 : -1
        let lunge = SKAction.moveBy(x: 12 * dir, y: 0, duration: 0.06)
        let back = SKAction.moveBy(x: -12 * dir, y: 0, duration: 0.1)
        run(SKAction.sequence([lunge, back])) {
            self.state = .idle
        }

        showSpeechBubble(Dialogues.randomThrow())
    }

    func getHit() {
        guard isAlive else { return }
        isAlive = false
        state = .hit
        removeAction(forKey: "blink")
        drawHitFace()

        // Flash white
        bodyCircle.run(SKAction.sequence([
            SKAction.colorize(with: .white, colorBlendFactor: 0.9, duration: 0.04),
            SKAction.wait(forDuration: 0.06),
            SKAction.colorize(with: .clear, colorBlendFactor: 0, duration: 0.1)
        ]))

        // Shake
        let shake = SKAction.sequence((0..<5).map { _ in
            SKAction.moveBy(x: CGFloat.random(in: -6...6), y: CGFloat.random(in: -3...3), duration: 0.035)
        })

        // Collapse
        let collapse = SKAction.sequence([
            shake,
            SKAction.group([
                SKAction.scale(to: 0.65, duration: 0.35),
                SKAction.rotate(toAngle: team == .player ? -CGFloat.pi / 2 : CGFloat.pi / 2, duration: 0.35),
                SKAction.fadeAlpha(to: 0.45, duration: 0.35)
            ]),
            SKAction.run { [weak self] in
                self?.state = .out
                self?.physicsBody?.categoryBitMask = 0
                self?.physicsBody?.contactTestBitMask = 0
                self?.physicsBody?.collisionBitMask = 0
            }
        ])
        run(collapse)

        showSpeechBubble(Dialogues.random(.gotHit))
        spawnHearts()
    }

    private func spawnHearts() {
        for i in 0..<6 {
            let emojis = ["💔", "🖤", "💜", "🩹"]
            let heart = SKLabelNode(text: emojis[i % emojis.count])
            heart.fontSize = CGFloat.random(in: 10...18)
            heart.position = .zero
            heart.zPosition = 12
            addChild(heart)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let dist = CGFloat.random(in: 35...70)
            heart.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: cos(angle) * dist, y: sin(angle) * dist, duration: 0.55),
                    SKAction.fadeOut(withDuration: 0.55),
                    SKAction.rotate(byAngle: CGFloat.random(in: -3...3), duration: 0.55)
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }

    func pickUpBall() {
        hasBall = true
        let bounce = SKAction.sequence([
            SKAction.scale(to: 1.18, duration: 0.06),
            SKAction.scale(to: 1.0, duration: 0.06)
        ])
        run(bounce)

        if Bool.random() {
            showSpeechBubble(Dialogues.random(.pickup))
        }
    }

    // MARK: - Speech Bubble

    func showSpeechBubble(_ text: String) {
        childNode(withName: "speechBubble")?.removeFromParent()

        let label = SKLabelNode(text: text)
        label.fontName = "HiraginoSans-W6"
        label.fontSize = 12
        label.fontColor = UIColor(red: 1, green: 0.9, blue: 0.95, alpha: 1)
        label.horizontalAlignmentMode = .center

        let padding: CGFloat = 10
        let bubbleWidth = max(label.frame.width + padding * 2, 65)
        let bubbleHeight: CGFloat = 26

        let bubble = SKShapeNode(rectOf: CGSize(width: bubbleWidth, height: bubbleHeight), cornerRadius: 10)
        bubble.fillColor = UIColor(red: 0.12, green: 0.08, blue: 0.22, alpha: 0.92)
        bubble.strokeColor = style.accessoryColor.withAlphaComponent(0.7)
        bubble.lineWidth = 1.5
        bubble.name = "speechBubble"
        bubble.position = CGPoint(x: 0, y: Character.radius + 22)
        bubble.zPosition = 20

        // Speech tail
        let tailPath = CGMutablePath()
        tailPath.move(to: CGPoint(x: -4, y: -bubbleHeight / 2))
        tailPath.addLine(to: CGPoint(x: 0, y: -bubbleHeight / 2 - 6))
        tailPath.addLine(to: CGPoint(x: 4, y: -bubbleHeight / 2))
        let tail = SKShapeNode(path: tailPath)
        tail.fillColor = bubble.fillColor
        tail.strokeColor = bubble.strokeColor
        tail.lineWidth = 1.5
        tail.zPosition = -1
        bubble.addChild(tail)

        label.verticalAlignmentMode = .center
        bubble.addChild(label)
        addChild(bubble)

        bubble.setScale(0.3)
        bubble.alpha = 0
        bubble.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.0, duration: 0.12),
                SKAction.fadeIn(withDuration: 0.08)
            ]),
            SKAction.group([
                SKAction.moveBy(x: 0, y: 20, duration: 1.2),
                SKAction.sequence([
                    SKAction.wait(forDuration: 0.7),
                    SKAction.fadeOut(withDuration: 0.5)
                ])
            ]),
            SKAction.removeFromParent()
        ]))
    }
}

// MARK: - UIColor extension

extension UIColor {
    func adjusted(brightness delta: CGFloat) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: h, saturation: s, brightness: max(0, min(1, b + delta)), alpha: a)
    }
}
