import SpriteKit
import Foundation

class AIController {

    weak var scene: GameScene?
    private var difficulty: Int = 1  // 1, 2, 3

    // Per-character AI state
    private var aiTimers: [ObjectIdentifier: TimeInterval] = [:]
    private var aiTargets: [ObjectIdentifier: SKPoint] = [:]
    private var aiCooldowns: [ObjectIdentifier: TimeInterval] = [:]

    typealias SKPoint = CGPoint

    init(scene: GameScene, difficulty: Int = 1) {
        self.scene = scene
        self.difficulty = difficulty
    }

    func setDifficulty(_ d: Int) {
        difficulty = max(1, min(3, d))
    }

    /// Call every frame from GameScene.update
    func update(deltaTime dt: TimeInterval, enemies: [Character], players: [Character], balls: [Ball], courtBounds: CGRect) {
        for enemy in enemies where enemy.isAlive {
            updateEnemy(enemy, dt: dt, players: players, balls: balls, courtBounds: courtBounds)
        }
    }

    private func updateEnemy(_ enemy: Character, dt: TimeInterval, players: [Character], balls: [Ball], courtBounds: CGRect) {
        let id = ObjectIdentifier(enemy)

        // Decrement cooldown
        let cooldown = (aiCooldowns[id] ?? 0) - dt
        aiCooldowns[id] = cooldown

        // Dodge incoming balls
        if shouldDodge(enemy: enemy, balls: balls) {
            dodgeBall(enemy: enemy, balls: balls, courtBounds: courtBounds)
            return
        }

        // If has ball, throw at players
        if enemy.hasBall {
            if cooldown <= 0 {
                throwAtPlayer(enemy: enemy, players: players)
            }
            return
        }

        // Find nearest available ball on enemy side or center
        if let ball = nearestBall(to: enemy, balls: balls, courtBounds: courtBounds) {
            moveToPickUp(enemy: enemy, ball: ball, courtBounds: courtBounds)
            return
        }

        // Wander within enemy half
        wander(enemy: enemy, dt: dt, courtBounds: courtBounds)
    }

    private func shouldDodge(enemy: Character, balls: [Ball]) -> Bool {
        let dodgeReaction: Double
        switch difficulty {
        case 1: dodgeReaction = 0.3
        case 2: dodgeReaction = 0.5
        default: dodgeReaction = 0.7
        }
        guard Double.random(in: 0...1) < dodgeReaction else { return false }

        for ball in balls where ball.isActive && ball.thrownByTeam == .player {
            let dist = hypot(ball.position.x - enemy.position.x,
                             ball.position.y - enemy.position.y)
            let vel = ball.physicsBody?.velocity ?? .zero
            let speed = hypot(vel.dx, vel.dy)
            if dist < 90 && speed > 80 {
                // Check if ball is heading toward this enemy
                let toEnemy = CGVector(dx: enemy.position.x - ball.position.x,
                                      dy: enemy.position.y - ball.position.y)
                let dot = vel.dx * toEnemy.dx + vel.dy * toEnemy.dy
                if dot > 0 { return true }
            }
        }
        return false
    }

    private func dodgeBall(enemy: Character, balls: [Ball], courtBounds: CGRect) {
        // Move perpendicular to incoming ball
        var dodgeDir = CGVector(dx: 0, dy: 0)
        for ball in balls where ball.isActive && ball.thrownByTeam == .player {
            let vel = ball.physicsBody?.velocity ?? .zero
            let speed = hypot(vel.dx, vel.dy)
            guard speed > 0 else { continue }
            // Perpendicular dodge
            dodgeDir = CGVector(dx: vel.dy / speed, dy: -vel.dx / speed)
            break
        }

        if dodgeDir.dx == 0 && dodgeDir.dy == 0 {
            dodgeDir = CGVector(dx: 0, dy: Bool.random() ? 1 : -1)
        }

        let dodgeDist: CGFloat = 50
        var target = CGPoint(x: enemy.position.x + dodgeDir.dx * dodgeDist,
                             y: enemy.position.y + dodgeDir.dy * dodgeDist)
        target = clampToEnemyHalf(point: target, bounds: courtBounds)
        enemy.setMoving(to: target)
    }

    private func nearestBall(to enemy: Character, balls: [Ball], courtBounds: CGRect) -> Ball? {
        // Only pick up balls that are not active (on the ground)
        let available = balls.filter { !$0.isActive }
        return available.min(by: {
            hypot($0.position.x - enemy.position.x, $0.position.y - enemy.position.y) <
            hypot($1.position.x - enemy.position.x, $1.position.y - enemy.position.y)
        })
    }

    private func moveToPickUp(enemy: Character, ball: Ball, courtBounds: CGRect) {
        // Only move if not already close
        let dist = hypot(ball.position.x - enemy.position.x,
                         ball.position.y - enemy.position.y)
        if dist > Character.radius * 2.5 {
            enemy.setMoving(to: ball.position)
        }
    }

    private func throwAtPlayer(enemy: Character, players: [Character]) {
        let alive = players.filter { $0.isAlive }
        guard let target = alive.min(by: {
            hypot($0.position.x - enemy.position.x, $0.position.y - enemy.position.y) <
            hypot($1.position.x - enemy.position.x, $1.position.y - enemy.position.y)
        }) else { return }

        let id = ObjectIdentifier(enemy)

        // Throw delay based on difficulty
        let delay: TimeInterval
        switch difficulty {
        case 1: delay = TimeInterval.random(in: 0.8...1.6)
        case 2: delay = TimeInterval.random(in: 0.4...1.0)
        default: delay = TimeInterval.random(in: 0.1...0.5)
        }
        aiCooldowns[id] = delay

        // Aim with some inaccuracy based on difficulty
        var aimPoint = target.position
        let inaccuracy: CGFloat
        switch difficulty {
        case 1: inaccuracy = 60
        case 2: inaccuracy = 30
        default: inaccuracy = 10
        }
        aimPoint.x += CGFloat.random(in: -inaccuracy...inaccuracy)
        aimPoint.y += CGFloat.random(in: -inaccuracy...inaccuracy)

        scene?.aiThrow(from: enemy, toward: aimPoint)
    }

    private func wander(enemy: Character, dt: TimeInterval, courtBounds: CGRect) {
        let id = ObjectIdentifier(enemy)
        let timer = (aiTimers[id] ?? 0) - dt
        aiTimers[id] = timer

        if timer <= 0 || enemy.state == .idle {
            // Pick a new wander target in enemy half
            let wanderInterval: TimeInterval = TimeInterval.random(in: 1.0...2.5)
            aiTimers[id] = wanderInterval

            let target = randomEnemyPosition(bounds: courtBounds)
            enemy.setMoving(to: target)
        }
    }

    private func randomEnemyPosition(bounds: CGRect) -> CGPoint {
        let margin: CGFloat = 30
        let x = CGFloat.random(in: (bounds.midX + margin)...(bounds.maxX - margin))
        let y = CGFloat.random(in: (bounds.minY + margin)...(bounds.maxY - margin))
        return CGPoint(x: x, y: y)
    }

    private func clampToEnemyHalf(point: CGPoint, bounds: CGRect) -> CGPoint {
        let margin: CGFloat = 25
        let x = max(bounds.midX + margin, min(bounds.maxX - margin, point.x))
        let y = max(bounds.minY + margin, min(bounds.maxY - margin, point.y))
        return CGPoint(x: x, y: y)
    }
}
