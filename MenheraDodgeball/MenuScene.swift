import SpriteKit

class MenuScene: SKScene {

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.1, green: 0.08, blue: 0.18, alpha: 1.0)
        setupBackground()
        setupTitle()
        setupStartButton()
        setupDecorations()
        setupAmbientParticles()
    }

    private func setupBackground() {
        // Gloomy gradient via two rect nodes
        let topRect = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height / 2))
        topRect.position = CGPoint(x: size.width / 2, y: size.height * 0.75)
        topRect.fillColor = UIColor(red: 0.08, green: 0.06, blue: 0.14, alpha: 1.0)
        topRect.strokeColor = .clear
        topRect.zPosition = -10
        addChild(topRect)

        let botRect = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height / 2))
        botRect.position = CGPoint(x: size.width / 2, y: size.height * 0.25)
        botRect.fillColor = UIColor(red: 0.12, green: 0.09, blue: 0.2, alpha: 1.0)
        botRect.strokeColor = .clear
        botRect.zPosition = -10
        addChild(botRect)

        // Floor lines (gym floor feel)
        for i in 0..<6 {
            let line = SKShapeNode()
            let path = CGMutablePath()
            let y = size.height * 0.15 + CGFloat(i) * 18
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            line.path = path
            line.strokeColor = UIColor(white: 1, alpha: 0.04)
            line.lineWidth = 1
            line.zPosition = -9
            addChild(line)
        }
    }

    private func setupTitle() {
        // Subtitle
        let subLabel = SKLabelNode(text: "〜病みかわいい ドッジボール〜")
        subLabel.fontName = "HiraMaruProN-W4"
        subLabel.fontSize = 14
        subLabel.fontColor = UIColor(red: 0.8, green: 0.6, blue: 0.9, alpha: 0.8)
        subLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.72)
        subLabel.zPosition = 5
        addChild(subLabel)

        // Main title - split into two lines for dramatic effect
        let title1 = SKLabelNode(text: "メンヘラ")
        title1.fontName = "HiraMaruProN-W4"
        title1.fontSize = 46
        title1.fontColor = UIColor(red: 1.0, green: 0.75, blue: 0.88, alpha: 1.0)
        title1.position = CGPoint(x: size.width / 2, y: size.height * 0.63)
        title1.zPosition = 5
        addChild(title1)

        let title2 = SKLabelNode(text: "ドッジボール")
        title2.fontName = "HiraMaruProN-W4"
        title2.fontSize = 36
        title2.fontColor = UIColor(red: 0.9, green: 0.55, blue: 0.75, alpha: 1.0)
        title2.position = CGPoint(x: size.width / 2, y: size.height * 0.555)
        title2.zPosition = 5
        addChild(title2)

        // Glitch pulse on title
        let pulse = SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.85, duration: 2.0),
            SKAction.fadeAlpha(to: 1.0, duration: 0.1),
            SKAction.fadeAlpha(to: 0.9, duration: 0.05),
            SKAction.fadeAlpha(to: 1.0, duration: 1.5)
        ]))
        title1.run(pulse)
        title2.run(pulse)
    }

    private func setupStartButton() {
        // Button background
        let btnBg = SKShapeNode(rectOf: CGSize(width: 180, height: 52), cornerRadius: 26)
        btnBg.position = CGPoint(x: size.width / 2, y: size.height * 0.38)
        btnBg.fillColor = UIColor(red: 0.9, green: 0.4, blue: 0.65, alpha: 1.0)
        btnBg.strokeColor = UIColor(red: 1.0, green: 0.7, blue: 0.85, alpha: 1.0)
        btnBg.lineWidth = 2
        btnBg.name = "startButton"
        btnBg.zPosition = 5
        addChild(btnBg)

        let btnLabel = SKLabelNode(text: "はじめる")
        btnLabel.fontName = "HiraMaruProN-W4"
        btnLabel.fontSize = 22
        btnLabel.fontColor = .white
        btnLabel.verticalAlignmentMode = .center
        btnLabel.name = "startButton"
        btnLabel.zPosition = 6
        btnBg.addChild(btnLabel)

        // Pulsing glow
        let glow = SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.04, duration: 0.7),
            SKAction.scale(to: 1.0, duration: 0.7)
        ]))
        btnBg.run(glow)

        // How to play
        let howto = SKLabelNode(text: "タップで移動  スワイプで投げる")
        howto.fontName = "HiraMaruProN-W4"
        howto.fontSize = 13
        howto.fontColor = UIColor(white: 1, alpha: 0.5)
        howto.position = CGPoint(x: size.width / 2, y: size.height * 0.3)
        howto.zPosition = 5
        addChild(howto)
    }

    private func setupDecorations() {
        // Decorative menhera characters on sides
        addDecorativeChar(at: CGPoint(x: size.width * 0.12, y: size.height * 0.48), team: .player, scale: 0.7)
        addDecorativeChar(at: CGPoint(x: size.width * 0.88, y: size.height * 0.48), team: .enemy, scale: 0.7)

        // Small hearts
        for _ in 0..<4 {
            let heart = SKLabelNode(text: Bool.random() ? "💔" : "🖤")
            heart.fontSize = CGFloat.random(in: 12...20)
            heart.position = CGPoint(x: CGFloat.random(in: 20...(size.width - 20)),
                                     y: CGFloat.random(in: size.height * 0.15...size.height * 0.45))
            heart.zPosition = 3
            heart.alpha = 0.4
            addChild(heart)

            let float = SKAction.repeatForever(SKAction.sequence([
                SKAction.moveBy(x: 0, y: 6, duration: Double.random(in: 1.2...2.0)),
                SKAction.moveBy(x: 0, y: -6, duration: Double.random(in: 1.2...2.0))
            ]))
            heart.run(float)
        }
    }

    private func addDecorativeChar(at pos: CGPoint, team: CharacterTeam, scale: CGFloat) {
        let char = Character(team: team)
        char.position = pos
        char.setScale(scale)
        char.zPosition = 3

        // Gentle sway
        let sway = SKAction.repeatForever(SKAction.sequence([
            SKAction.rotate(toAngle: 0.15, duration: 1.0),
            SKAction.rotate(toAngle: -0.15, duration: 1.0)
        ]))
        char.run(sway)
        addChild(char)
    }

    private func setupAmbientParticles() {
        // Floating dark sparkles
        let spawn = SKAction.repeatForever(SKAction.sequence([
            SKAction.run { [weak self] in
                guard let self = self else { return }
                let dot = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...3))
                dot.position = CGPoint(x: CGFloat.random(in: 0...self.size.width),
                                       y: -10)
                dot.fillColor = UIColor(red: CGFloat.random(in: 0.7...1.0),
                                        green: CGFloat.random(in: 0.3...0.6),
                                        blue: CGFloat.random(in: 0.7...1.0),
                                        alpha: 0.6)
                dot.strokeColor = .clear
                dot.zPosition = 1
                self.addChild(dot)

                let rise = SKAction.sequence([
                    SKAction.group([
                        SKAction.moveBy(x: CGFloat.random(in: -20...20),
                                        y: self.size.height + 20,
                                        duration: Double.random(in: 3.0...6.0)),
                        SKAction.sequence([
                            SKAction.fadeIn(withDuration: 0.3),
                            SKAction.wait(forDuration: 2.0),
                            SKAction.fadeOut(withDuration: 0.8)
                        ])
                    ]),
                    SKAction.removeFromParent()
                ])
                dot.run(rise)
            },
            SKAction.wait(forDuration: 0.3)
        ]))
        run(spawn)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        let nodes = self.nodes(at: loc)

        if nodes.contains(where: { $0.name == "startButton" }) {
            transitionToGame()
        }
    }

    private func transitionToGame() {
        // Button tap feedback
        if let btn = childNode(withName: "startButton") as? SKShapeNode {
            btn.run(SKAction.sequence([
                SKAction.scale(to: 0.92, duration: 0.08),
                SKAction.scale(to: 1.0, duration: 0.08)
            ]))
        }

        run(SKAction.wait(forDuration: 0.2)) {
            let gameScene = GameScene(size: self.size)
            gameScene.scaleMode = .aspectFill
            let transition = SKTransition.fade(with: UIColor(red: 0.1, green: 0.05, blue: 0.15, alpha: 1),
                                               duration: 0.6)
            self.view?.presentScene(gameScene, transition: transition)
        }
    }
}
