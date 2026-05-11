import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {

    // MARK: - Game State
    private var playerTeam: [Character] = []
    private var enemyTeam: [Character] = []
    private var balls: [Ball] = []
    private var aiController: AIController!

    private var playerWins: Int = 0
    private var enemyWins: Int = 0
    private var currentRound: Int = 1
    private let maxRounds: Int = 3

    private var gameActive: Bool = false
    private var roundEnding: Bool = false

    // Touch handling
    private var selectedCharacter: Character?
    private var touchStart: CGPoint?
    private var touchStartTime: TimeInterval = 0
    private var swipeIndicator: SKShapeNode?

    // UI Nodes
    private var roundLabel: SKLabelNode!
    private var scoreLabel: SKLabelNode!
    private var instructionLabel: SKLabelNode!
    private var courtNode: SKNode!
    private var centerLine: SKShapeNode!

    // Court dimensions
    private var courtRect: CGRect = .zero
    private let courtMargin: CGFloat = 20

    // Ball carrier indicator
    private var ballIndicator: SKShapeNode?

    // Last update time for delta
    private var lastUpdateTime: TimeInterval = 0

    // MARK: - Setup

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.1, green: 0.08, blue: 0.15, alpha: 1.0)
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self

        courtRect = CGRect(x: courtMargin,
                           y: size.height * 0.12,
                           width: size.width - courtMargin * 2,
                           height: size.height * 0.72)

        setupWalls()
        setupCourt()
        setupHUD()
        setupBalls()
        setupTeams()
        aiController = AIController(scene: self, difficulty: 1)

        startRound()
    }

    private func setupWalls() {
        // Invisible boundary walls matching courtRect
        let walls: [(CGPoint, CGSize)] = [
            // Bottom
            (CGPoint(x: size.width / 2, y: courtRect.minY - 5),
             CGSize(width: courtRect.width + 20, height: 10)),
            // Top
            (CGPoint(x: size.width / 2, y: courtRect.maxY + 5),
             CGSize(width: courtRect.width + 20, height: 10)),
            // Left
            (CGPoint(x: courtRect.minX - 5, y: courtRect.midY),
             CGSize(width: 10, height: courtRect.height + 20)),
            // Right
            (CGPoint(x: courtRect.maxX + 5, y: courtRect.midY),
             CGSize(width: 10, height: courtRect.height + 20))
        ]

        for (pos, sz) in walls {
            let wall = SKNode()
            wall.position = pos
            wall.physicsBody = SKPhysicsBody(rectangleOf: sz)
            wall.physicsBody?.isDynamic = false
            wall.physicsBody?.categoryBitMask = PhysicsCategory.wall.rawValue
            wall.physicsBody?.collisionBitMask = PhysicsCategory.ball.rawValue | PhysicsCategory.player.rawValue | PhysicsCategory.enemy.rawValue
            wall.physicsBody?.contactTestBitMask = 0
            addChild(wall)
        }
    }

    private func setupCourt() {
        courtNode = SKNode()
        addChild(courtNode)

        // Floor
        let floor = SKShapeNode(rectOf: courtRect.size, cornerRadius: 6)
        floor.position = CGPoint(x: courtRect.midX, y: courtRect.midY)
        floor.fillColor = UIColor(red: 0.14, green: 0.11, blue: 0.22, alpha: 1.0)
        floor.strokeColor = UIColor(white: 1, alpha: 0.15)
        floor.lineWidth = 2
        floor.zPosition = -5
        courtNode.addChild(floor)

        // Gym floor lines
        for i in 0..<8 {
            let line = SKShapeNode()
            let path = CGMutablePath()
            let y = courtRect.minY + CGFloat(i + 1) * (courtRect.height / 9)
            path.move(to: CGPoint(x: courtRect.minX + 8, y: y))
            path.addLine(to: CGPoint(x: courtRect.maxX - 8, y: y))
            line.path = path
            line.strokeColor = UIColor(white: 1, alpha: 0.04)
            line.lineWidth = 1
            line.zPosition = -4
            courtNode.addChild(line)
        }

        // Center dashed line
        centerLine = makeDashedLine(from: CGPoint(x: courtRect.midX, y: courtRect.minY + 8),
                                    to: CGPoint(x: courtRect.midX, y: courtRect.maxY - 8))
        courtNode.addChild(centerLine)

        // Center circle
        let centerCircle = SKShapeNode(circleOfRadius: 35)
        centerCircle.position = CGPoint(x: courtRect.midX, y: courtRect.midY)
        centerCircle.fillColor = .clear
        centerCircle.strokeColor = UIColor(white: 1, alpha: 0.2)
        centerCircle.lineWidth = 1.5
        centerCircle.zPosition = -4
        courtNode.addChild(centerCircle)

        // Player half label
        let playerHalfLabel = SKLabelNode(text: "あなた")
        playerHalfLabel.fontName = "HiraMaruProN-W4"
        playerHalfLabel.fontSize = 11
        playerHalfLabel.fontColor = UIColor(white: 1, alpha: 0.2)
        playerHalfLabel.position = CGPoint(x: courtRect.midX * 0.55, y: courtRect.maxY - 16)
        playerHalfLabel.zPosition = -3
        courtNode.addChild(playerHalfLabel)

        let enemyHalfLabel = SKLabelNode(text: "てき")
        enemyHalfLabel.fontName = "HiraMaruProN-W4"
        enemyHalfLabel.fontSize = 11
        enemyHalfLabel.fontColor = UIColor(white: 1, alpha: 0.2)
        enemyHalfLabel.position = CGPoint(x: courtRect.midX + (size.width - courtRect.midX) * 0.5, y: courtRect.maxY - 16)
        enemyHalfLabel.zPosition = -3
        courtNode.addChild(enemyHalfLabel)
    }

    private func makeDashedLine(from start: CGPoint, to end: CGPoint) -> SKShapeNode {
        let path = CGMutablePath()
        path.move(to: start)
        path.addLine(to: end)
        let line = SKShapeNode(path: path)
        line.strokeColor = UIColor(white: 1, alpha: 0.35)
        line.lineWidth = 2
        line.zPosition = -3
        return line
    }

    private func setupHUD() {
        // Top bar background
        let topBar = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height * 0.11))
        topBar.position = CGPoint(x: size.width / 2, y: size.height - size.height * 0.055)
        topBar.fillColor = UIColor(red: 0.08, green: 0.06, blue: 0.12, alpha: 0.95)
        topBar.strokeColor = UIColor(white: 1, alpha: 0.08)
        topBar.lineWidth = 1
        topBar.zPosition = 20
        addChild(topBar)

        roundLabel = SKLabelNode(text: "Round 1")
        roundLabel.fontName = "HiraMaruProN-W4"
        roundLabel.fontSize = 16
        roundLabel.fontColor = UIColor(red: 1, green: 0.75, blue: 0.88, alpha: 1)
        roundLabel.position = CGPoint(x: size.width / 2, y: size.height - size.height * 0.07)
        roundLabel.zPosition = 21
        addChild(roundLabel)

        scoreLabel = SKLabelNode(text: "🖤🖤🖤  vs  🖤🖤🖤")
        scoreLabel.fontName = "HiraMaruProN-W4"
        scoreLabel.fontSize = 14
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height - size.height * 0.1)
        scoreLabel.zPosition = 21
        addChild(scoreLabel)

        // Bottom instruction
        let bottomBar = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height * 0.1))
        bottomBar.position = CGPoint(x: size.width / 2, y: size.height * 0.055)
        bottomBar.fillColor = UIColor(red: 0.08, green: 0.06, blue: 0.12, alpha: 0.9)
        bottomBar.strokeColor = UIColor(white: 1, alpha: 0.08)
        bottomBar.lineWidth = 1
        bottomBar.zPosition = 20
        addChild(bottomBar)

        instructionLabel = SKLabelNode(text: "キャラをタップして選択 → コートをタップで移動")
        instructionLabel.fontName = "HiraMaruProN-W4"
        instructionLabel.fontSize = 11
        instructionLabel.fontColor = UIColor(white: 1, alpha: 0.5)
        instructionLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.03)
        instructionLabel.zPosition = 21
        addChild(instructionLabel)
    }

    private func setupBalls() {
        // Place 3 balls at center line
        let ballPositions: [CGPoint] = [
            CGPoint(x: courtRect.midX, y: courtRect.midY - 50),
            CGPoint(x: courtRect.midX, y: courtRect.midY),
            CGPoint(x: courtRect.midX, y: courtRect.midY + 50)
        ]
        for pos in ballPositions {
            let ball = Ball()
            ball.position = pos
            ball.zPosition = 3
            addChild(ball)
            balls.append(ball)
        }
    }

    private func setupTeams() {
        let teamSize = 3
        let playerX = courtRect.minX + courtRect.width * 0.2
        let enemyX = courtRect.minX + courtRect.width * 0.8
        let spacing = courtRect.height / CGFloat(teamSize + 1)

        for i in 0..<teamSize {
            let y = courtRect.minY + spacing * CGFloat(i + 1)

            let player = Character(team: .player, index: i)
            player.position = CGPoint(x: playerX, y: y)
            player.zPosition = 5
            addChild(player)
            playerTeam.append(player)

            let enemy = Character(team: .enemy, index: i)
            enemy.position = CGPoint(x: enemyX, y: y)
            enemy.zPosition = 5
            addChild(enemy)
            enemyTeam.append(enemy)
        }
    }

    // MARK: - Round Management

    private func startRound() {
        gameActive = false
        roundEnding = false
        selectedCharacter = nil
        clearBallIndicator()

        roundLabel.text = "Round \(currentRound)"
        updateScoreDisplay()

        // Countdown
        showCountdown {
            self.gameActive = true
            self.aiController.setDifficulty(self.currentRound)
            self.instructionLabel.text = "キャラをタップ → 移動 | ボールを持ってスワイプで投げる"
            // Round start dialogue from a random player character
            self.playerTeam.filter { $0.isAlive }.randomElement()?
                .showSpeechBubble(Dialogues.random(.roundStart))
        }
    }

    private func showCountdown(completion: @escaping () -> Void) {
        let messages = ["3", "2", "1", "スタート！"]
        var delay: TimeInterval = 0.2

        for (i, msg) in messages.enumerated() {
            run(SKAction.wait(forDuration: delay)) {
                self.showBigMessage(msg, duration: 0.7)
            }
            delay += (i < 3) ? 0.9 : 1.1
        }

        run(SKAction.wait(forDuration: delay)) {
            completion()
        }
    }

    private func showBigMessage(_ text: String, duration: TimeInterval) {
        let label = SKLabelNode(text: text)
        label.fontName = "HiraMaruProN-W4"
        label.fontSize = 64
        label.fontColor = UIColor(red: 1, green: 0.8, blue: 0.9, alpha: 1.0)
        label.position = CGPoint(x: size.width / 2, y: size.height / 2)
        label.zPosition = 50
        label.setScale(0.3)
        addChild(label)

        label.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.0, duration: 0.15),
                SKAction.fadeIn(withDuration: 0.1)
            ]),
            SKAction.wait(forDuration: duration * 0.6),
            SKAction.group([
                SKAction.scale(to: 1.3, duration: duration * 0.4),
                SKAction.fadeOut(withDuration: duration * 0.4)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    private func checkRoundEnd() {
        guard gameActive, !roundEnding else { return }

        let alivePlayers = playerTeam.filter { $0.isAlive }
        let aliveEnemies = enemyTeam.filter { $0.isAlive }

        // "Last one standing" dialogue
        if alivePlayers.count == 1 && aliveEnemies.count > 0 {
            alivePlayers.first?.showSpeechBubble(Dialogues.random(.lastOne))
        } else if aliveEnemies.count == 1 && alivePlayers.count > 0 {
            aliveEnemies.first?.showSpeechBubble(Dialogues.random(.lastOne))
        }

        if alivePlayers.isEmpty || aliveEnemies.isEmpty {
            roundEnding = true
            gameActive = false

            let playerWon = !alivePlayers.isEmpty
            if playerWon {
                playerWins += 1
                showBigMessage("ラウンド勝利！", duration: 1.5)
            } else {
                enemyWins += 1
                showBigMessage("ラウンド敗北...", duration: 1.5)
            }

            updateScoreDisplay()

            run(SKAction.wait(forDuration: 2.2)) {
                self.proceedAfterRound()
            }
        }
    }

    private func proceedAfterRound() {
        if playerWins >= 2 || enemyWins >= 2 {
            // Match over
            goToResult()
        } else {
            currentRound += 1
            resetRound()
        }
    }

    private func resetRound() {
        // Remove old characters
        for c in playerTeam { c.removeFromParent() }
        for c in enemyTeam { c.removeFromParent() }
        for b in balls { b.removeFromParent() }
        playerTeam.removeAll()
        enemyTeam.removeAll()
        balls.removeAll()

        setupBalls()
        setupTeams()
        startRound()
    }

    private func goToResult() {
        let result = ResultScene(size: size, playerWins: playerWins, enemyWins: enemyWins)
        result.scaleMode = .aspectFill
        let t = SKTransition.fade(with: UIColor(red: 0.08, green: 0.05, blue: 0.15, alpha: 1), duration: 0.7)
        view?.presentScene(result, transition: t)
    }

    private func updateScoreDisplay() {
        var pStr = ""
        var eStr = ""
        for i in 0..<maxRounds {
            pStr += i < playerWins ? "❤️" : "🖤"
            eStr += i < enemyWins ? "❤️" : "🖤"
        }
        scoreLabel.text = "\(pStr)  vs  \(eStr)"
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        touchStart = loc
        touchStartTime = touch.timestamp

        // Check if tapping a player character to select
        for char in playerTeam where char.isAlive {
            let dist = hypot(loc.x - char.position.x, loc.y - char.position.y)
            if dist < Character.radius + 16 {
                selectCharacter(char)
                return
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let start = touchStart,
              let selected = selectedCharacter,
              selected.hasBall else { return }

        let loc = touch.location(in: self)
        let dx = loc.x - start.x
        let dy = loc.y - start.y
        let dist = hypot(dx, dy)

        // Show swipe indicator if swiping enough
        if dist > 20 {
            updateSwipeIndicator(from: selected.position,
                                 direction: CGPoint(x: dx / dist, y: dy / dist),
                                 dist: min(dist, 80))
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let start = touchStart else { return }
        let loc = touch.location(in: self)
        let dx = loc.x - start.x
        let dy = loc.y - start.y
        let dist = hypot(dx, dy)
        let elapsed = touch.timestamp - touchStartTime

        clearSwipeIndicator()

        if dist > 35 && elapsed < 0.6 {
            // Swipe gesture - throw ball if selected char has it
            if let selected = selectedCharacter, selected.hasBall, selected.isAlive {
                let throwTarget = CGPoint(x: selected.position.x + dx * 4,
                                         y: selected.position.y + dy * 4)
                performThrow(from: selected, toward: throwTarget)
            }
        } else if dist < 20 {
            // Tap gesture
            handleTap(at: loc)
        }

        touchStart = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchStart = nil
        clearSwipeIndicator()
    }

    private func handleTap(at loc: CGPoint) {
        guard gameActive else { return }

        // If tapping a player char, select it
        for char in playerTeam where char.isAlive {
            let dist = hypot(loc.x - char.position.x, loc.y - char.position.y)
            if dist < Character.radius + 16 {
                selectCharacter(char)
                return
            }
        }

        // If a character is selected, move to tapped location (player half only)
        if let selected = selectedCharacter, selected.isAlive {
            // Clamp to player half
            let clampedX = max(courtRect.minX + Character.radius,
                               min(courtRect.midX - Character.radius - 2, loc.x))
            let clampedY = max(courtRect.minY + Character.radius,
                               min(courtRect.maxY - Character.radius, loc.y))
            let dest = CGPoint(x: clampedX, y: clampedY)

            selected.setMoving(to: dest)
            showMoveTarget(at: dest)
        }
    }

    private func selectCharacter(_ char: Character) {
        // Deselect previous
        if let prev = selectedCharacter {
            deselectVisual(prev)
        }
        selectedCharacter = char
        applySelectVisual(char)

        // Update instruction
        if char.hasBall {
            instructionLabel.text = "スワイプで投げる！"
        } else {
            instructionLabel.text = "タップで移動"
        }
    }

    private func applySelectVisual(_ char: Character) {
        let ring = SKShapeNode(circleOfRadius: Character.radius + 6)
        ring.strokeColor = UIColor(red: 1, green: 0.8, blue: 0.9, alpha: 0.9)
        ring.fillColor = UIColor(red: 1, green: 0.8, blue: 0.9, alpha: 0.1)
        ring.lineWidth = 2
        ring.name = "selectionRing"
        ring.zPosition = 4
        ring.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.08, duration: 0.4),
            SKAction.scale(to: 1.0, duration: 0.4)
        ])))
        char.addChild(ring)
    }

    private func deselectVisual(_ char: Character) {
        char.childNode(withName: "selectionRing")?.removeFromParent()
    }

    private func showMoveTarget(at pos: CGPoint) {
        let marker = SKShapeNode(circleOfRadius: 8)
        marker.strokeColor = UIColor(red: 1, green: 0.7, blue: 0.85, alpha: 0.7)
        marker.fillColor = UIColor(red: 1, green: 0.7, blue: 0.85, alpha: 0.15)
        marker.lineWidth = 1.5
        marker.position = pos
        marker.zPosition = 2
        addChild(marker)
        marker.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 0.3, duration: 0.4),
                SKAction.fadeOut(withDuration: 0.4)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    private func updateSwipeIndicator(from origin: CGPoint, direction: CGPoint, dist: CGFloat) {
        clearSwipeIndicator()

        let indicator = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: origin)
        path.addLine(to: CGPoint(x: origin.x + direction.x * dist * 1.5,
                                 y: origin.y + direction.y * dist * 1.5))
        indicator.path = path
        indicator.strokeColor = UIColor(red: 1, green: 0.5, blue: 0.7, alpha: 0.7)
        indicator.lineWidth = 2
        indicator.zPosition = 10
        addChild(indicator)
        swipeIndicator = indicator

        // Arrow head
        let arrowHead = SKShapeNode(circleOfRadius: 5)
        arrowHead.position = CGPoint(x: origin.x + direction.x * dist * 1.5,
                                     y: origin.y + direction.y * dist * 1.5)
        arrowHead.fillColor = UIColor(red: 1, green: 0.5, blue: 0.7, alpha: 0.8)
        arrowHead.strokeColor = .clear
        arrowHead.zPosition = 10
        arrowHead.name = "arrowHead"
        addChild(arrowHead)
    }

    private func clearSwipeIndicator() {
        swipeIndicator?.removeFromParent()
        swipeIndicator = nil
        childNode(withName: "arrowHead")?.removeFromParent()
    }

    // MARK: - Ball Throwing

    func performThrow(from character: Character, toward target: CGPoint) {
        guard let ball = balls.first(where: { !$0.isActive }), character.hasBall else { return }

        let charIndex = playerTeam.firstIndex(where: { $0 === character }) ?? 0
        let dialogue = Dialogues.throwDialogue(
            myScore: playerTeam.filter { $0.isAlive }.count,
            enemyScore: enemyTeam.filter { $0.isAlive }.count
        )

        // Pause game for cut-in
        gameActive = false

        let cutIn = CutInOverlay()
        cutIn.show(in: self, characterIndex: charIndex, isPlayer: true, dialogue: dialogue) { [weak self] in
            guard let self = self else { return }

            character.hasBall = false
            character.throwBall()
            self.deselectVisual(character)
            self.selectedCharacter = nil

            ball.thrownByTeam = .player
            ball.position = character.position
            ball.launch(toward: target, from: character.position, speed: 440)

            self.clearBallIndicator()
            self.instructionLabel.text = "キャラをタップ → 移動 | ボールを持ってスワイプで投げる"
            self.flashScreen(color: UIColor(red: 1, green: 0.6, blue: 0.8, alpha: 0.12))

            self.gameActive = true
        }
    }

    func aiThrow(from enemy: Character, toward target: CGPoint) {
        guard let ball = balls.first(where: { !$0.isActive }), enemy.hasBall else { return }

        let charIndex = enemyTeam.firstIndex(where: { $0 === enemy }) ?? 0
        let dialogue = Dialogues.randomThrow()

        gameActive = false

        let cutIn = CutInOverlay()
        cutIn.show(in: self, characterIndex: charIndex, isPlayer: false, dialogue: dialogue) { [weak self] in
            guard let self = self else { return }

            enemy.hasBall = false
            enemy.throwBall()

            ball.thrownByTeam = .enemy
            ball.position = enemy.position
            ball.launch(toward: target, from: enemy.position, speed: 340 + CGFloat(self.currentRound * 30))

            self.gameActive = true
        }
    }

    private func flashScreen(color: UIColor) {
        let flash = SKShapeNode(rectOf: size)
        flash.position = CGPoint(x: size.width / 2, y: size.height / 2)
        flash.fillColor = color
        flash.strokeColor = .clear
        flash.zPosition = 100
        addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.15),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Ball Carrier Indicator

    private func updateBallIndicator() {
        clearBallIndicator()
        // Show pulsing arrow above player who has ball
        for char in playerTeam where char.isAlive && char.hasBall {
            let arrow = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: -6, y: -10))
            path.addLine(to: CGPoint(x: 6, y: -10))
            path.closeSubpath()
            arrow.path = path
            arrow.fillColor = UIColor(red: 1, green: 0.7, blue: 0.3, alpha: 0.9)
            arrow.strokeColor = .clear
            arrow.position = CGPoint(x: char.position.x, y: char.position.y + Character.radius + 18)
            arrow.zPosition = 8
            arrow.name = "ballIndicator"
            addChild(arrow)
            arrow.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.moveBy(x: 0, y: 3, duration: 0.4),
                SKAction.moveBy(x: 0, y: -3, duration: 0.4)
            ])))
            ballIndicator = arrow
        }
    }

    private func clearBallIndicator() {
        enumerateChildNodes(withName: "ballIndicator") { n, _ in n.removeFromParent() }
        ballIndicator = nil
    }

    // MARK: - Physics Contact

    func didBegin(_ contact: SKPhysicsContact) {
        let a = contact.bodyA
        let b = contact.bodyB

        let ballBody = [a, b].first { $0.categoryBitMask == PhysicsCategory.ball.rawValue }
        let charBody = [a, b].first {
            $0.categoryBitMask == PhysicsCategory.player.rawValue ||
            $0.categoryBitMask == PhysicsCategory.enemy.rawValue
        }

        guard let ballPhy = ballBody, let charPhy = charBody else { return }
        guard let ball = ballPhy.node?.parent as? Ball ?? ballPhy.node as? Ball,
              let char = charPhy.node as? Character else { return }

        handleBallHit(ball: ball, character: char)
    }

    private func handleBallHit(ball: Ball, character: Character) {
        guard ball.isActive else { return }
        guard character.isAlive else { return }

        // Ball must be thrown by opposing team
        if ball.thrownByTeam == .player && character.team == .player { return }
        if ball.thrownByTeam == .enemy && character.team == .enemy { return }

        ball.deactivate()
        character.getHit()

        // Show "hit enemy" dialogue on the thrower
        let throwerTeam = ball.thrownByTeam
        let throwers = (throwerTeam == .player ? playerTeam : enemyTeam).filter { $0.isAlive }
        throwers.first?.showSpeechBubble(Dialogues.random(.hitEnemy))

        // Camera shake via scene position wobble
        let shake = SKAction.sequence([
            SKAction.moveBy(x: -5, y: 2, duration: 0.03),
            SKAction.moveBy(x: 10, y: -4, duration: 0.03),
            SKAction.moveBy(x: -7, y: 3, duration: 0.03),
            SKAction.moveBy(x: 4, y: -2, duration: 0.03),
            SKAction.moveBy(x: -2, y: 1, duration: 0.03)
        ])
        courtNode.run(shake)

        flashScreen(color: UIColor(red: 1, green: 0.2, blue: 0.4, alpha: 0.18))

        // Deselect if hit char was selected
        if selectedCharacter === character {
            selectedCharacter = nil
            clearBallIndicator()
        }

        run(SKAction.wait(forDuration: 0.6)) {
            self.checkRoundEnd()
        }
    }

    // MARK: - Update Loop

    override func update(_ currentTime: TimeInterval) {
        let dt = lastUpdateTime == 0 ? 0 : currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        guard gameActive else { return }

        // Ball pickup logic
        checkBallPickups()

        // AI update
        aiController.update(
            deltaTime: dt,
            enemies: enemyTeam,
            players: playerTeam,
            balls: balls,
            courtBounds: courtRect
        )

        // Update ball indicator
        updateBallIndicator()
    }

    private func checkBallPickups() {
        let allChars = playerTeam + enemyTeam
        for char in allChars where char.isAlive && !char.hasBall {
            for ball in balls where !ball.isActive {
                let dist = hypot(ball.position.x - char.position.x,
                                 ball.position.y - char.position.y)
                if dist < Character.radius + Ball.radius + 4 {
                    // Only pick up ball on own half
                    let onPlayerHalf = ball.position.x < courtRect.midX
                    let onEnemyHalf = ball.position.x >= courtRect.midX

                    if (char.team == .player && onPlayerHalf) ||
                       (char.team == .enemy && onEnemyHalf) {
                        char.pickUpBall()
                        ball.resetBall(at: ball.position)
                        // Visually attach ball to carrier (snap to char)
                        break
                    }
                }
            }
        }
    }
}
