import SpriteKit

class ResultScene: SKScene {

    private let playerWins: Int
    private let enemyWins: Int
    private let playerWon: Bool

    init(size: CGSize, playerWins: Int, enemyWins: Int) {
        self.playerWins = playerWins
        self.enemyWins = enemyWins
        self.playerWon = playerWins > enemyWins
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.08, green: 0.06, blue: 0.14, alpha: 1.0)
        setupBackground()
        setupResult()
        setupScore()
        setupButtons()
        setupEffects()
    }

    private func setupBackground() {
        // Vignette-like darkening at edges via overlapping translucent shapes
        let vignette = SKShapeNode(rectOf: size)
        vignette.position = CGPoint(x: size.width / 2, y: size.height / 2)
        vignette.fillColor = playerWon ?
            UIColor(red: 0.6, green: 0.1, blue: 0.3, alpha: 0.08) :
            UIColor(red: 0.1, green: 0.05, blue: 0.2, alpha: 0.15)
        vignette.strokeColor = .clear
        vignette.zPosition = -5
        addChild(vignette)
    }

    private func setupResult() {
        if playerWon {
            // Win state
            let winLabel = SKLabelNode(text: "勝ったよ！")
            winLabel.fontName = "HiraMaruProN-W4"
            winLabel.fontSize = 52
            winLabel.fontColor = UIColor(red: 1.0, green: 0.8, blue: 0.9, alpha: 1.0)
            winLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.68)
            winLabel.zPosition = 5
            addChild(winLabel)

            let subLabel = SKLabelNode(text: Dialogues.random(.victory))
            subLabel.fontName = "HiraMaruProN-W4"
            subLabel.fontSize = 17
            subLabel.fontColor = UIColor(white: 1, alpha: 0.7)
            subLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.60)
            subLabel.zPosition = 5
            addChild(subLabel)

            // Floating hearts on win
            spawnWinHearts()
        } else {
            // Lose state
            let loseLabel = SKLabelNode(text: "負けちゃった...")
            loseLabel.fontName = "HiraMaruProN-W4"
            loseLabel.fontSize = 46
            loseLabel.fontColor = UIColor(red: 0.7, green: 0.5, blue: 0.9, alpha: 1.0)
            loseLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.68)
            loseLabel.zPosition = 5
            addChild(loseLabel)

            let subLabel = SKLabelNode(text: Dialogues.random(.defeat))
            subLabel.fontName = "HiraMaruProN-W4"
            subLabel.fontSize = 16
            subLabel.fontColor = UIColor(white: 1, alpha: 0.55)
            subLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.60)
            subLabel.zPosition = 5
            addChild(subLabel)

            // Fallen characters
            for i in 0..<3 {
                let char = Character(team: .player, index: i)
                char.position = CGPoint(x: size.width * (0.25 + CGFloat(i) * 0.25), y: size.height * 0.46)
                char.zRotation = CGFloat.random(in: -1.2...(-0.8))
                char.setScale(1.2)
                char.alpha = 0.5
                char.zPosition = 5
                addChild(char)
            }
        }
    }

    private func setupScore() {
        // Score display with broken heart icons
        let scoreY = size.height * 0.35

        let scoreBg = SKShapeNode(rectOf: CGSize(width: 220, height: 54), cornerRadius: 12)
        scoreBg.position = CGPoint(x: size.width / 2, y: scoreY)
        scoreBg.fillColor = UIColor(white: 1, alpha: 0.06)
        scoreBg.strokeColor = UIColor(white: 1, alpha: 0.15)
        scoreBg.lineWidth = 1
        scoreBg.zPosition = 5
        addChild(scoreBg)

        // Build score string with heart icons
        var pHearts = ""
        var eHearts = ""
        for i in 0..<3 {
            pHearts += i < playerWins ? "❤️" : "🖤"
            eHearts += i < enemyWins ? "❤️" : "🖤"
        }

        let scoreText = "\(pHearts)  vs  \(eHearts)"
        let scoreLabel = SKLabelNode(text: scoreText)
        scoreLabel.fontName = "HiraMaruProN-W4"
        scoreLabel.fontSize = 18
        scoreLabel.fontColor = .white
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.zPosition = 6
        scoreBg.addChild(scoreLabel)
    }

    private func setupButtons() {
        // Play again button
        let playBtn = makeButton(text: "もう一回", color: UIColor(red: 0.8, green: 0.35, blue: 0.6, alpha: 1.0))
        playBtn.position = CGPoint(x: size.width / 2, y: size.height * 0.22)
        playBtn.name = "playAgain"
        addChild(playBtn)

        // Menu button
        let menuBtn = makeButton(text: "タイトルへ", color: UIColor(red: 0.25, green: 0.18, blue: 0.35, alpha: 1.0))
        menuBtn.position = CGPoint(x: size.width / 2, y: size.height * 0.13)
        menuBtn.name = "menu"
        addChild(menuBtn)
    }

    private func makeButton(text: String, color: UIColor) -> SKShapeNode {
        let btn = SKShapeNode(rectOf: CGSize(width: 190, height: 48), cornerRadius: 24)
        btn.fillColor = color
        btn.strokeColor = UIColor(white: 1, alpha: 0.3)
        btn.lineWidth = 1.5
        btn.zPosition = 5

        let label = SKLabelNode(text: text)
        label.fontName = "HiraMaruProN-W4"
        label.fontSize = 20
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.zPosition = 6
        btn.addChild(label)

        let pulse = SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.85, duration: 1.0),
            SKAction.fadeAlpha(to: 1.0, duration: 1.0)
        ]))
        btn.run(pulse)

        return btn
    }

    private func setupEffects() {
        if playerWon {
            // Confetti-like dots
            let spawn = SKAction.repeatForever(SKAction.sequence([
                SKAction.run { [weak self] in
                    guard let self = self else { return }
                    let colors: [UIColor] = [
                        UIColor(red: 1, green: 0.7, blue: 0.85, alpha: 0.9),
                        UIColor(red: 0.8, green: 0.5, blue: 1.0, alpha: 0.9),
                        UIColor(red: 1, green: 0.9, blue: 0.5, alpha: 0.9)
                    ]
                    let dot = SKShapeNode(circleOfRadius: CGFloat.random(in: 3...7))
                    dot.fillColor = colors.randomElement()!
                    dot.strokeColor = .clear
                    dot.position = CGPoint(x: CGFloat.random(in: 0...self.size.width),
                                           y: self.size.height + 10)
                    dot.zPosition = 3
                    self.addChild(dot)

                    dot.run(SKAction.sequence([
                        SKAction.group([
                            SKAction.moveBy(x: CGFloat.random(in: -30...30),
                                            y: -(self.size.height + 30),
                                            duration: Double.random(in: 1.5...3.0)),
                            SKAction.rotate(byAngle: CGFloat.random(in: -4...4),
                                            duration: Double.random(in: 1.5...3.0))
                        ]),
                        SKAction.removeFromParent()
                    ]))
                },
                SKAction.wait(forDuration: 0.08)
            ]))
            run(spawn)
        } else {
            // Falling tears
            let spawn = SKAction.repeatForever(SKAction.sequence([
                SKAction.run { [weak self] in
                    guard let self = self else { return }
                    let tear = SKShapeNode(ellipseOf: CGSize(width: 5, height: 8))
                    tear.fillColor = UIColor(red: 0.6, green: 0.7, blue: 1.0, alpha: 0.5)
                    tear.strokeColor = .clear
                    tear.position = CGPoint(x: CGFloat.random(in: 0...self.size.width),
                                            y: self.size.height)
                    tear.zPosition = 3
                    self.addChild(tear)

                    tear.run(SKAction.sequence([
                        SKAction.moveBy(x: CGFloat.random(in: -10...10),
                                        y: -(self.size.height + 20),
                                        duration: Double.random(in: 2.0...4.0)),
                        SKAction.removeFromParent()
                    ]))
                },
                SKAction.wait(forDuration: 0.15)
            ]))
            run(spawn)
        }
    }

    private func spawnWinHearts() {
        let spawn = SKAction.repeatForever(SKAction.sequence([
            SKAction.run { [weak self] in
                guard let self = self else { return }
                let heart = SKLabelNode(text: Bool.random() ? "💕" : "✨")
                heart.fontSize = CGFloat.random(in: 14...28)
                heart.position = CGPoint(x: CGFloat.random(in: 20...(self.size.width - 20)),
                                         y: -10)
                heart.zPosition = 3
                self.addChild(heart)

                heart.run(SKAction.sequence([
                    SKAction.group([
                        SKAction.moveBy(x: CGFloat.random(in: -15...15),
                                        y: self.size.height + 30,
                                        duration: Double.random(in: 2.0...4.0)),
                        SKAction.sequence([
                            SKAction.fadeIn(withDuration: 0.2),
                            SKAction.wait(forDuration: 1.5),
                            SKAction.fadeOut(withDuration: 0.5)
                        ])
                    ]),
                    SKAction.removeFromParent()
                ]))
            },
            SKAction.wait(forDuration: 0.25)
        ]))
        run(spawn)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        let nodes = self.nodes(at: loc)

        for node in nodes {
            if node.name == "playAgain" || node.parent?.name == "playAgain" {
                tapFeedback(node: node.name == "playAgain" ? node as? SKShapeNode : node.parent as? SKShapeNode)
                run(SKAction.wait(forDuration: 0.2)) {
                    let scene = GameScene(size: self.size)
                    scene.scaleMode = .aspectFill
                    let t = SKTransition.fade(with: UIColor(red: 0.08, green: 0.05, blue: 0.15, alpha: 1), duration: 0.5)
                    self.view?.presentScene(scene, transition: t)
                }
                return
            }
            if node.name == "menu" || node.parent?.name == "menu" {
                tapFeedback(node: node.name == "menu" ? node as? SKShapeNode : node.parent as? SKShapeNode)
                run(SKAction.wait(forDuration: 0.2)) {
                    let scene = MenuScene(size: self.size)
                    scene.scaleMode = .aspectFill
                    let t = SKTransition.fade(with: UIColor(red: 0.08, green: 0.05, blue: 0.15, alpha: 1), duration: 0.5)
                    self.view?.presentScene(scene, transition: t)
                }
                return
            }
        }
    }

    private func tapFeedback(node: SKShapeNode?) {
        node?.run(SKAction.sequence([
            SKAction.scale(to: 0.93, duration: 0.07),
            SKAction.scale(to: 1.0, duration: 0.07)
        ]))
    }
}
