import SpriteKit

class CutInOverlay: SKNode {

    static let playerNames = ["メンヘラちゃん", "ヤミちゃん", "ツンデレちゃん"]
    static let enemyNames = ["サイコちゃん", "ナミダちゃん", "ステッチちゃん"]

    override init() {
        super.init()
        zPosition = 900
        isUserInteractionEnabled = false
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    func show(in scene: SKScene, characterIndex: Int, isPlayer: Bool, dialogue: String, completion: @escaping () -> Void) {
        removeAllChildren()
        removeAllActions()

        let sceneSize = scene.size
        let idx = min(characterIndex, 2)

        // Full-screen dark overlay
        let overlay = SKShapeNode(rectOf: sceneSize)
        overlay.fillColor = .black
        overlay.strokeColor = .clear
        overlay.alpha = 0
        overlay.zPosition = 0
        addChild(overlay)

        // Diagonal slash background
        let slashColor = isPlayer
            ? UIColor(red: 0.9, green: 0.2, blue: 0.5, alpha: 0.88)
            : UIColor(red: 0.35, green: 0.1, blue: 0.55, alpha: 0.88)

        let slash = createSlash(size: sceneSize, color: slashColor)
        slash.alpha = 0
        addChild(slash)

        // Secondary accent slash
        let accentColor = isPlayer
            ? UIColor(red: 1.0, green: 0.6, blue: 0.8, alpha: 0.3)
            : UIColor(red: 0.6, green: 0.3, blue: 0.8, alpha: 0.3)
        let slash2 = createAccentSlash(size: sceneSize, color: accentColor)
        slash2.alpha = 0
        addChild(slash2)

        // Portrait
        let styles = isPlayer ? Character.playerStyles : Character.enemyStyles
        let style = styles[idx]
        let portraitNode = createPortrait(style: style, hairStyle: style.hairStyle, size: 200)
        portraitNode.position = CGPoint(x: -sceneSize.width * 0.22, y: 10)
        portraitNode.zPosition = 2
        portraitNode.alpha = 0
        portraitNode.setScale(1.8)
        addChild(portraitNode)

        // Character name with background
        let names = isPlayer ? CutInOverlay.playerNames : CutInOverlay.enemyNames
        let nameTag = createNameTag(name: names[idx], color: slashColor, sceneSize: sceneSize)
        nameTag.position = CGPoint(x: sceneSize.width * 0.18, y: 50)
        nameTag.alpha = 0
        addChild(nameTag)

        // Dialogue bubble
        let dialogueBubble = createDialogueBubble(text: dialogue, color: slashColor, sceneSize: sceneSize)
        dialogueBubble.position = CGPoint(x: sceneSize.width * 0.18, y: -15)
        dialogueBubble.alpha = 0
        addChild(dialogueBubble)

        // Speed lines
        spawnSpeedLines(sceneSize: sceneSize, color: isPlayer ? .systemPink : .purple)

        // Manga-style impact lines at edges
        spawnImpactBurst(sceneSize: sceneSize)

        // Animate in
        let dur = 0.13
        overlay.run(.fadeAlpha(to: 0.55, duration: dur))
        slash.run(.sequence([.group([.fadeIn(withDuration: dur), .moveBy(x: 40, y: 0, duration: dur)])]))
        slash2.run(.sequence([.wait(forDuration: 0.03), .group([.fadeIn(withDuration: dur), .moveBy(x: 25, y: 0, duration: dur)])]))
        portraitNode.run(.sequence([.wait(forDuration: 0.04), .group([.fadeIn(withDuration: dur), .scale(to: 1.0, duration: dur * 1.5)])]))
        nameTag.run(.sequence([.wait(forDuration: 0.08), .fadeIn(withDuration: 0.1)]))
        dialogueBubble.run(.sequence([.wait(forDuration: 0.1), .fadeIn(withDuration: 0.1)]))

        // Hold then dismiss
        run(.sequence([
            .wait(forDuration: 0.95),
            .run { [weak self] in
                self?.children.forEach { $0.run(.fadeOut(withDuration: 0.1)) }
            },
            .wait(forDuration: 0.12),
            .run { [weak self] in
                self?.removeFromParent()
                completion()
            }
        ]))

        scene.addChild(self)
    }

    // MARK: - Slash backgrounds

    private func createSlash(size: CGSize, color: UIColor) -> SKShapeNode {
        let w = size.width
        let h = size.height
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -w * 0.6, y: -h / 2))
        path.addLine(to: CGPoint(x: w * 0.1, y: -h / 2))
        path.addLine(to: CGPoint(x: -w * 0.1, y: h / 2))
        path.addLine(to: CGPoint(x: -w * 0.6, y: h / 2))
        path.closeSubpath()
        let slash = SKShapeNode(path: path)
        slash.fillColor = color
        slash.strokeColor = .white
        slash.lineWidth = 3
        slash.zPosition = 1
        return slash
    }

    private func createAccentSlash(size: CGSize, color: UIColor) -> SKShapeNode {
        let w = size.width
        let h = size.height
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -w * 0.12, y: -h / 2))
        path.addLine(to: CGPoint(x: w * 0.02, y: -h / 2))
        path.addLine(to: CGPoint(x: -w * 0.18, y: h / 2))
        path.addLine(to: CGPoint(x: -w * 0.32, y: h / 2))
        path.closeSubpath()
        let slash = SKShapeNode(path: path)
        slash.fillColor = color
        slash.strokeColor = .clear
        slash.zPosition = 1
        return slash
    }

    // MARK: - Portrait

    private func createPortrait(style: Character.CharacterStyle, hairStyle: Int, size: CGFloat) -> SKNode {
        let container = SKNode()
        let scale = size / 48.0

        // Face circle
        let face = SKShapeNode(circleOfRadius: 80)
        face.fillColor = style.bodyColor
        face.strokeColor = style.strokeColor
        face.lineWidth = 3
        face.zPosition = 0
        container.addChild(face)

        // Hair background
        let hairBg = SKShapeNode(circleOfRadius: 88)
        hairBg.fillColor = style.hairColor
        hairBg.strokeColor = .clear
        hairBg.zPosition = -1

        let hairMask = SKCropNode()
        let maskNode = SKShapeNode(rectOf: CGSize(width: 200, height: 100))
        maskNode.fillColor = .white
        maskNode.position = CGPoint(x: 0, y: 50)
        hairMask.maskNode = maskNode
        hairMask.addChild(hairBg)
        container.addChild(hairMask)

        // Hair details per style
        switch hairStyle {
        case 0: // Twintails
            for side: CGFloat in [-1, 1] {
                let tail = SKShapeNode(ellipseOf: CGSize(width: 40, height: 90))
                tail.position = CGPoint(x: side * 85, y: -10)
                tail.fillColor = style.hairColor
                tail.strokeColor = style.hairColor.adjusted(brightness: -0.15)
                tail.lineWidth = 2
                tail.zPosition = -1
                tail.zRotation = side * 0.15
                container.addChild(tail)

                let ribbon = SKShapeNode(rectOf: CGSize(width: 18, height: 10), cornerRadius: 3)
                ribbon.position = CGPoint(x: side * 78, y: 30)
                ribbon.fillColor = style.accessoryColor
                ribbon.strokeColor = style.accessoryColor.adjusted(brightness: -0.2)
                ribbon.lineWidth = 1
                ribbon.zPosition = 3
                ribbon.zRotation = side * 0.3
                container.addChild(ribbon)
            }
        case 1: // Bob cut
            for side: CGFloat in [-1, 1] {
                let sideHair = SKShapeNode(rectOf: CGSize(width: 30, height: 55), cornerRadius: 12)
                sideHair.position = CGPoint(x: side * 78, y: -15)
                sideHair.fillColor = style.hairColor
                sideHair.strokeColor = .clear
                sideHair.zPosition = -1
                container.addChild(sideHair)
            }
        default: // Long
            for side: CGFloat in [-1, 1] {
                let strand = SKShapeNode(rectOf: CGSize(width: 32, height: 100), cornerRadius: 14)
                strand.position = CGPoint(x: side * 80, y: -30)
                strand.fillColor = style.hairColor
                strand.strokeColor = .clear
                strand.zPosition = -1
                strand.zRotation = side * 0.06
                container.addChild(strand)
            }
        }

        // Bangs
        let bangPath = CGMutablePath()
        bangPath.move(to: CGPoint(x: -70, y: 40))
        bangPath.addCurve(to: CGPoint(x: 0, y: 28), control1: CGPoint(x: -40, y: 75), control2: CGPoint(x: -15, y: 55))
        bangPath.addCurve(to: CGPoint(x: 70, y: 40), control1: CGPoint(x: 15, y: 55), control2: CGPoint(x: 40, y: 75))
        let bangs = SKShapeNode(path: bangPath)
        bangs.fillColor = style.hairColor
        bangs.strokeColor = style.hairColor.adjusted(brightness: -0.1)
        bangs.lineWidth = 1.5
        bangs.zPosition = 3
        container.addChild(bangs)

        // Eyes - large anime style
        for (xPos, side) in [(-28.0, -1.0), (28.0, 1.0)] as [(CGFloat, CGFloat)] {
            let eyeWhite = SKShapeNode(ellipseOf: CGSize(width: 32, height: 36))
            eyeWhite.position = CGPoint(x: xPos, y: 5)
            eyeWhite.fillColor = .white
            eyeWhite.strokeColor = style.eyeColor.withAlphaComponent(0.3)
            eyeWhite.lineWidth = 1.5
            eyeWhite.zPosition = 4

            let iris = SKShapeNode(circleOfRadius: 13)
            iris.fillColor = style.eyeColor
            iris.strokeColor = style.eyeColor.adjusted(brightness: -0.3)
            iris.lineWidth = 1
            iris.zPosition = 1

            let pupil = SKShapeNode(circleOfRadius: 6)
            pupil.fillColor = UIColor(white: 0.05, alpha: 1)
            pupil.strokeColor = .clear
            pupil.zPosition = 2
            iris.addChild(pupil)

            let shine1 = SKShapeNode(circleOfRadius: 5)
            shine1.position = CGPoint(x: side * 4, y: 4)
            shine1.fillColor = .white
            shine1.strokeColor = .clear
            shine1.zPosition = 3
            iris.addChild(shine1)

            let shine2 = SKShapeNode(circleOfRadius: 2.5)
            shine2.position = CGPoint(x: side * -3, y: -4)
            shine2.fillColor = UIColor(white: 1, alpha: 0.6)
            shine2.strokeColor = .clear
            shine2.zPosition = 3
            iris.addChild(shine2)

            eyeWhite.addChild(iris)
            container.addChild(eyeWhite)
        }

        // Blush
        for x: CGFloat in [-35, 35] {
            let blush = SKShapeNode(ellipseOf: CGSize(width: 28, height: 14))
            blush.position = CGPoint(x: x, y: -10)
            blush.fillColor = style.blushColor
            blush.strokeColor = .clear
            blush.zPosition = 4
            container.addChild(blush)
        }

        // Mouth
        let mouthPath = CGMutablePath()
        mouthPath.move(to: CGPoint(x: -12, y: -25))
        mouthPath.addCurve(to: CGPoint(x: 0, y: -20), control1: CGPoint(x: -6, y: -32), control2: CGPoint(x: -3, y: -20))
        mouthPath.addCurve(to: CGPoint(x: 12, y: -25), control1: CGPoint(x: 3, y: -20), control2: CGPoint(x: 6, y: -32))
        let mouth = SKShapeNode(path: mouthPath)
        mouth.strokeColor = style.eyeColor.withAlphaComponent(0.6)
        mouth.lineWidth = 2
        mouth.fillColor = .clear
        mouth.zPosition = 5
        container.addChild(mouth)

        // Bandage
        let bnd = SKShapeNode(rectOf: CGSize(width: 36, height: 16), cornerRadius: 5)
        bnd.position = CGPoint(x: 15, y: 55)
        bnd.fillColor = UIColor(white: 0.97, alpha: 0.95)
        bnd.strokeColor = UIColor(white: 0.82, alpha: 1)
        bnd.lineWidth = 1
        bnd.zRotation = 0.2
        bnd.zPosition = 5
        let c1 = SKShapeNode(rectOf: CGSize(width: 22, height: 2.5))
        c1.fillColor = style.accessoryColor.withAlphaComponent(0.6)
        c1.strokeColor = .clear
        bnd.addChild(c1)
        let c2 = SKShapeNode(rectOf: CGSize(width: 2.5, height: 10))
        c2.fillColor = style.accessoryColor.withAlphaComponent(0.6)
        c2.strokeColor = .clear
        bnd.addChild(c2)
        container.addChild(bnd)

        container.setScale(scale * 0.26)
        return container
    }

    // MARK: - UI Elements

    private func createNameTag(name: String, color: UIColor, sceneSize: CGSize) -> SKNode {
        let container = SKNode()
        container.zPosition = 3

        let bg = SKShapeNode(rectOf: CGSize(width: sceneSize.width * 0.48, height: 34), cornerRadius: 6)
        bg.fillColor = color.withAlphaComponent(0.85)
        bg.strokeColor = .white
        bg.lineWidth = 1.5
        container.addChild(bg)

        let label = SKLabelNode(text: name)
        label.fontName = "HiraginoSans-W8"
        label.fontSize = 20
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        container.addChild(label)

        return container
    }

    private func createDialogueBubble(text: String, color: UIColor, sceneSize: CGSize) -> SKNode {
        let container = SKNode()
        container.zPosition = 3

        let bg = SKShapeNode(rectOf: CGSize(width: sceneSize.width * 0.55, height: 72), cornerRadius: 14)
        bg.fillColor = UIColor(red: 0.06, green: 0.04, blue: 0.1, alpha: 0.88)
        bg.strokeColor = color.withAlphaComponent(0.6)
        bg.lineWidth = 2
        container.addChild(bg)

        // Inner glow line
        let innerGlow = SKShapeNode(rectOf: CGSize(width: sceneSize.width * 0.53, height: 68), cornerRadius: 12)
        innerGlow.fillColor = .clear
        innerGlow.strokeColor = color.withAlphaComponent(0.15)
        innerGlow.lineWidth = 1
        container.addChild(innerGlow)

        let dialogueNode = SKLabelNode(text: text)
        dialogueNode.fontName = "HiraginoSans-W6"
        dialogueNode.fontSize = 18
        dialogueNode.fontColor = .white
        dialogueNode.preferredMaxLayoutWidth = sceneSize.width * 0.48
        dialogueNode.numberOfLines = 2
        dialogueNode.verticalAlignmentMode = .center
        dialogueNode.zPosition = 1
        container.addChild(dialogueNode)

        return container
    }

    // MARK: - Effects

    private func spawnSpeedLines(sceneSize: CGSize, color: UIColor) {
        for _ in 0..<15 {
            let lineWidth = CGFloat.random(in: 1.5...4)
            let lineHeight = sceneSize.height * CGFloat.random(in: 0.25...0.9)
            let line = SKShapeNode(rectOf: CGSize(width: lineWidth, height: lineHeight))
            line.fillColor = .white
            line.strokeColor = .clear
            line.alpha = 0
            line.position = CGPoint(
                x: CGFloat.random(in: -sceneSize.width / 2...sceneSize.width / 2),
                y: CGFloat.random(in: -sceneSize.height / 2...sceneSize.height / 2)
            )
            line.zRotation = CGFloat.random(in: -0.25...0.25)
            line.zPosition = 1
            addChild(line)

            line.run(.sequence([
                .wait(forDuration: Double.random(in: 0...0.05)),
                .fadeAlpha(to: CGFloat.random(in: 0.08...0.25), duration: 0.08),
                .wait(forDuration: 0.75),
                .fadeOut(withDuration: 0.12)
            ]))
        }
    }

    private func spawnImpactBurst(sceneSize: CGSize) {
        // Radial burst lines from center-left
        let burstCenter = CGPoint(x: -sceneSize.width * 0.15, y: 0)
        for i in 0..<8 {
            let angle = CGFloat(i) * (.pi * 2 / 8) + CGFloat.random(in: -0.2...0.2)
            let length = CGFloat.random(in: 40...90)

            let line = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: burstCenter.x + cos(angle) * 30,
                                  y: burstCenter.y + sin(angle) * 30))
            path.addLine(to: CGPoint(x: burstCenter.x + cos(angle) * (30 + length),
                                     y: burstCenter.y + sin(angle) * (30 + length)))
            line.path = path
            line.strokeColor = UIColor(white: 1, alpha: 0.4)
            line.lineWidth = CGFloat.random(in: 1...3)
            line.zPosition = 2
            line.alpha = 0
            addChild(line)

            line.run(.sequence([
                .wait(forDuration: 0.06),
                .fadeAlpha(to: 0.6, duration: 0.06),
                .wait(forDuration: 0.6),
                .fadeOut(withDuration: 0.15)
            ]))
        }
    }
}
