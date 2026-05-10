import SpriteKit

class CutInOverlay: SKNode {

    private let background = SKShapeNode()
    private let portrait = SKSpriteNode()
    private let speechLabel = SKLabelNode()
    private let nameLabel = SKLabelNode()

    // Character portrait image names
    static let playerPortraits = ["player1_cutin", "player2_cutin", "player3_cutin"]
    static let enemyPortraits = ["enemy1_cutin", "enemy2_cutin", "enemy3_cutin"]

    override init() {
        super.init()
        zPosition = 900
        isUserInteractionEnabled = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Show a dramatic cut-in when a character grabs a ball or throws
    func show(in scene: SKScene, characterIndex: Int, isPlayer: Bool, dialogue: String, completion: @escaping () -> Void) {
        removeAllChildren()
        removeAllActions()

        let sceneSize = scene.size

        // Full-screen dark overlay
        let overlay = SKShapeNode(rectOf: sceneSize)
        overlay.fillColor = .black
        overlay.strokeColor = .clear
        overlay.alpha = 0
        overlay.zPosition = 0
        addChild(overlay)

        // Diagonal slash background
        let slash = SKShapeNode()
        let slashPath = CGMutablePath()
        let w = sceneSize.width
        let h = sceneSize.height
        slashPath.move(to: CGPoint(x: -w * 0.6, y: -h / 2))
        slashPath.addLine(to: CGPoint(x: w * 0.1, y: -h / 2))
        slashPath.addLine(to: CGPoint(x: -w * 0.1, y: h / 2))
        slashPath.addLine(to: CGPoint(x: -w * 0.6, y: h / 2))
        slashPath.closeSubpath()
        slash.path = slashPath
        slash.fillColor = isPlayer ? UIColor(red: 0.9, green: 0.2, blue: 0.5, alpha: 0.85) : UIColor(red: 0.4, green: 0.1, blue: 0.6, alpha: 0.85)
        slash.strokeColor = .white
        slash.lineWidth = 3
        slash.zPosition = 1
        slash.alpha = 0
        addChild(slash)

        // Portrait
        let portraits = isPlayer ? CutInOverlay.playerPortraits : CutInOverlay.enemyPortraits
        let idx = min(characterIndex, portraits.count - 1)
        let portraitName = portraits[idx]

        // Try to load image, fallback to procedural
        let portraitNode: SKNode
        if let _ = UIImage(named: portraitName) {
            let sprite = SKSpriteNode(imageNamed: portraitName)
            sprite.size = CGSize(width: 280, height: 280)
            portraitNode = sprite
        } else {
            portraitNode = createProceduralPortrait(index: characterIndex, isPlayer: isPlayer)
        }
        portraitNode.position = CGPoint(x: -sceneSize.width * 0.22, y: 0)
        portraitNode.zPosition = 2
        portraitNode.alpha = 0
        portraitNode.setScale(1.5)
        addChild(portraitNode)

        // Character name
        let names = isPlayer
            ? ["メンヘラちゃん", "ヤミちゃん", "ツンデレちゃん"]
            : ["サイコちゃん", "ナミダちゃん", "ステッチちゃん"]
        let nameNode = SKLabelNode(text: names[min(characterIndex, 2)])
        nameNode.fontName = "HiraginoSans-W7"
        nameNode.fontSize = 22
        nameNode.fontColor = .white
        nameNode.position = CGPoint(x: sceneSize.width * 0.15, y: 40)
        nameNode.zPosition = 3
        nameNode.alpha = 0
        addChild(nameNode)

        // Dialogue bubble
        let bubbleBg = SKShapeNode(rectOf: CGSize(width: sceneSize.width * 0.55, height: 80), cornerRadius: 12)
        bubbleBg.fillColor = UIColor(white: 0, alpha: 0.7)
        bubbleBg.strokeColor = isPlayer ? .systemPink : .purple
        bubbleBg.lineWidth = 2
        bubbleBg.position = CGPoint(x: sceneSize.width * 0.15, y: -20)
        bubbleBg.zPosition = 3
        bubbleBg.alpha = 0
        addChild(bubbleBg)

        let dialogueNode = SKLabelNode(text: dialogue)
        dialogueNode.fontName = "HiraginoSans-W6"
        dialogueNode.fontSize = 20
        dialogueNode.fontColor = .white
        dialogueNode.preferredMaxLayoutWidth = sceneSize.width * 0.5
        dialogueNode.numberOfLines = 2
        dialogueNode.verticalAlignmentMode = .center
        dialogueNode.position = CGPoint(x: sceneSize.width * 0.15, y: -20)
        dialogueNode.zPosition = 4
        dialogueNode.alpha = 0
        addChild(dialogueNode)

        // Speed lines
        for i in 0..<12 {
            let line = SKShapeNode(rectOf: CGSize(width: CGFloat.random(in: 2...5), height: sceneSize.height * CGFloat.random(in: 0.3...1.0)))
            line.fillColor = .white
            line.strokeColor = .clear
            line.alpha = 0
            line.position = CGPoint(
                x: CGFloat.random(in: -sceneSize.width/2...sceneSize.width/2),
                y: CGFloat.random(in: -sceneSize.height/2...sceneSize.height/2)
            )
            line.zRotation = CGFloat.random(in: -0.3...0.3)
            line.zPosition = 1
            addChild(line)
            line.run(.sequence([
                .wait(forDuration: 0.05),
                .fadeAlpha(to: CGFloat.random(in: 0.1...0.3), duration: 0.1),
                .wait(forDuration: 0.8),
                .fadeOut(withDuration: 0.15)
            ]))
        }

        // Animate in
        let animDuration = 0.15
        overlay.run(.fadeAlpha(to: 0.5, duration: animDuration))
        slash.run(.sequence([
            .group([
                .fadeIn(withDuration: animDuration),
                .moveBy(x: 30, y: 0, duration: animDuration)
            ])
        ]))
        portraitNode.run(.sequence([
            .wait(forDuration: 0.05),
            .group([
                .fadeIn(withDuration: animDuration),
                .scale(to: 1.0, duration: animDuration * 1.5)
            ])
        ]))
        nameNode.run(.sequence([.wait(forDuration: 0.1), .fadeIn(withDuration: 0.1)]))
        bubbleBg.run(.sequence([.wait(forDuration: 0.1), .fadeIn(withDuration: 0.1)]))
        dialogueNode.run(.sequence([.wait(forDuration: 0.12), .fadeIn(withDuration: 0.1)]))

        // Hold then dismiss
        run(.sequence([
            .wait(forDuration: 1.0),
            .run { [weak self] in
                self?.children.forEach { child in
                    child.run(.fadeOut(withDuration: 0.12))
                }
            },
            .wait(forDuration: 0.15),
            .run { [weak self] in
                self?.removeFromParent()
                completion()
            }
        ]))

        scene.addChild(self)
    }

    /// Procedural fallback portrait when image assets aren't available
    private func createProceduralPortrait(index: Int, isPlayer: Bool) -> SKNode {
        let container = SKNode()

        let colors: [UIColor] = isPlayer
            ? [.systemPink, UIColor(red: 0.3, green: 0.1, blue: 0.3, alpha: 1), .white]
            : [.purple, UIColor(red: 0.1, green: 0.2, blue: 0.4, alpha: 1), UIColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1)]

        let color = colors[min(index, 2)]

        // Face circle
        let face = SKShapeNode(circleOfRadius: 100)
        face.fillColor = UIColor(white: 0.9, alpha: 1)
        face.strokeColor = color
        face.lineWidth = 4
        container.addChild(face)

        // Hair
        let hair = SKShapeNode(circleOfRadius: 105)
        hair.fillColor = color
        hair.strokeColor = .clear
        let hairCrop = SKCropNode()
        let hairMask = SKShapeNode(rectOf: CGSize(width: 220, height: 110))
        hairMask.fillColor = .white
        hairMask.position = CGPoint(x: 0, y: 50)
        hairCrop.maskNode = hairMask
        hairCrop.addChild(hair)
        container.addChild(hairCrop)

        // Eyes
        let eyeExpressions: [(left: String, right: String)] = [
            ("◉", "◉"),   // intense stare
            ("×", "◉"),   // one eye X
            ("◉", "◉"),   // normal
        ]
        let expr = eyeExpressions[min(index, 2)]

        let leftEye = SKLabelNode(text: expr.left)
        leftEye.fontSize = 36
        leftEye.fontColor = color
        leftEye.position = CGPoint(x: -30, y: -10)
        container.addChild(leftEye)

        let rightEye = SKLabelNode(text: expr.right)
        rightEye.fontSize = 36
        rightEye.fontColor = color
        rightEye.position = CGPoint(x: 30, y: -10)
        container.addChild(rightEye)

        // Mouth
        let mouths = ["∀", "ω", "д"]
        let mouth = SKLabelNode(text: mouths[min(index, 2)])
        mouth.fontSize = 28
        mouth.fontColor = UIColor(red: 0.8, green: 0.2, blue: 0.3, alpha: 1)
        mouth.position = CGPoint(x: 0, y: -50)
        container.addChild(mouth)

        // Bandage
        if index == 0 || index == 2 {
            let bandage = SKLabelNode(text: "✚")
            bandage.fontSize = 30
            bandage.fontColor = .white
            bandage.position = CGPoint(x: index == 0 ? 60 : -60, y: 20)
            container.addChild(bandage)
        }

        // Tears
        if index == 1 {
            for x in [-25, 25] {
                let tear = SKShapeNode(ellipseOf: CGSize(width: 6, height: 16))
                tear.fillColor = .cyan
                tear.strokeColor = .clear
                tear.position = CGPoint(x: CGFloat(x), y: -30)
                container.addChild(tear)
            }
        }

        return container
    }
}
