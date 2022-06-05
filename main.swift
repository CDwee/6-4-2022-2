// Started at 6:34 6-4-2022

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var playerShip : SKSpriteNode?
    var labelNode : SKLabelNode?
    var backgroundNode : SKSpriteNode?
    
    let bulletSize = CGSize(width: 10, height: 40)
    let bulletSpeed : CGFloat = 20
    var isGameOver = false
    var alienCount = 9
    var fontSize : CGFloat = 100
    var losingPoint : CGFloat = -300
    var timeUntilSpeedUp = 120
    var timeUntilAlienFires = 60
    var listOfAliens = [SKNode]()
    
    enum bitMasks : UInt32 {
        case edgeBitMask = 0b1
        case playerShipBitMask = 0b10
        case alienShipBitMask = 0b100
        case bulletBitMask = 0b1000
    }
    
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        backgroundNode = self.childNode(withName: "backgroundNode") as? SKSpriteNode
        backgroundNode?.zPosition = -1
        
        playerShip = self.childNode(withName: "playerShip") as? SKSpriteNode
        labelNode = SKLabelNode(text: "")
        labelNode?.position = CGPoint(x: 0, y: 0)
        labelNode?.fontSize = fontSize
        labelNode?.fontColor = UIColor.white
        
        let edgePhysicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        edgePhysicsBody.restitution = 0
        edgePhysicsBody.friction = 1
        edgePhysicsBody.affectedByGravity = false
        edgePhysicsBody.categoryBitMask = bitMasks.edgeBitMask.rawValue
        edgePhysicsBody.collisionBitMask = bitMasks.bulletBitMask.rawValue
        edgePhysicsBody.contactTestBitMask = bitMasks.bulletBitMask.rawValue
        self.physicsBody = edgePhysicsBody
        
        for node in self.children {
            if node.name == "alienShip" {
                listOfAliens.append(node)
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            
            if isGameOver {
                labelNode?.removeFromParent()
                if let scene = SKScene(fileNamed: "GameScene") {
                    scene.size = self.size
                    scene.scaleMode = self.scaleMode
                    self.view?.presentScene(scene)
                }
            }
            
            let location = t.location(in: self)
            
            if self.nodes(at: location).contains(playerShip!) {
                spawnBullet()
            }
            playerShip?.position = CGPoint(x: location.x, y: (playerShip?.position.y)!)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            let xLocation = t.location(in: self).x
            playerShip?.position = CGPoint(x: xLocation, y: (playerShip?.position.y)!)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            
        }
    }
    
    func spawnBullet() {
        let bulletNode = SKShapeNode(rectOf: bulletSize)
        bulletNode.position = CGPoint(x: (playerShip?.frame.midX)!, y: (playerShip?.frame.maxY)!)
        bulletNode.fillColor = UIColor.red
        bulletNode.name = "bullet"
        self.addChild(bulletNode)
        
        let bulletPhysics = SKPhysicsBody(rectangleOf: bulletSize)
        bulletPhysics.affectedByGravity = false
        bulletPhysics.allowsRotation = false
        bulletPhysics.angularDamping = 0
        bulletPhysics.linearDamping = 0
        bulletPhysics.friction = 0
        bulletPhysics.restitution = 0
        bulletPhysics.isDynamic = true
        bulletPhysics.categoryBitMask = bitMasks.bulletBitMask.rawValue
        bulletPhysics.collisionBitMask = bitMasks.edgeBitMask.rawValue | bitMasks.alienShipBitMask.rawValue
        bulletPhysics.contactTestBitMask = bitMasks.edgeBitMask.rawValue | bitMasks.alienShipBitMask.rawValue
        bulletNode.physicsBody = bulletPhysics
        bulletNode.physicsBody?.applyImpulse(CGVector(dx: 0, dy: bulletSpeed))
    }
    
    func spawnAlienBullet() {
        let bulletNode = SKShapeNode(rectOf: bulletSize)
        
        let randomNumber = Int(arc4random_uniform(UInt32(listOfAliens.count)))
        let selectedAlien = listOfAliens[randomNumber]
        
        bulletNode.position = CGPoint(x: (selectedAlien.frame.midX), y: (selectedAlien.frame.minY))
        bulletNode.fillColor = UIColor.blue
        bulletNode.name = "alienBullet"
        self.addChild(bulletNode)
        
        let bulletPhysics = SKPhysicsBody(rectangleOf: bulletSize)
        bulletPhysics.affectedByGravity = false
        bulletPhysics.allowsRotation = false
        bulletPhysics.angularDamping = 0
        bulletPhysics.linearDamping = 0
        bulletPhysics.friction = 0
        bulletPhysics.restitution = 0
        bulletPhysics.isDynamic = true
        
        bulletPhysics.categoryBitMask = bitMasks.alienShipBitMask.rawValue
        bulletPhysics.collisionBitMask = bitMasks.edgeBitMask.rawValue | bitMasks.playerShipBitMask.rawValue
        bulletPhysics.contactTestBitMask = bitMasks.edgeBitMask.rawValue | bitMasks.playerShipBitMask.rawValue
        
        bulletNode.physicsBody = bulletPhysics
        
        bulletNode.physicsBody?.applyImpulse(CGVector(dx: 0, dy: -bulletSpeed))
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        var bulletNode : SKNode!
        var otherNode : SKNode!
        
        if contact.bodyA.node?.name == "bullet" || contact.bodyA.node?.name == "alienBullet" {
            bulletNode = contact.bodyA.node
            otherNode = contact.bodyB.node
        } else if contact.bodyB.node?.name == "bullet" || contact.bodyB.node?.name == "alienBullet" {
            bulletNode = contact.bodyB.node
            otherNode = contact.bodyA.node
        } else {
            return
        }
        
        if otherNode.name == "alienShip" {
            otherNode.removeFromParent()
            
            for node in listOfAliens {
                if node == otherNode {
                    listOfAliens.remove(at: listOfAliens.index(of: node)!)
                }
            }
            
            alienCount -= 1
            if alienCount == 0 {
                isGameOver = true
                labelNode?.text = "You win! :)"
                self.addChild(labelNode!)
                self.isPaused = true
            }
        }
        
        else if otherNode.name == "playerShip" {
            isGameOver = true
            labelNode?.text = "You lose! :("
            self.addChild(labelNode!)
            self.isPaused = true
        }
        
        bulletNode.removeFromParent()
    }
    
    override func update(_ currentTime: TimeInterval) {
        
        for node in self.children {
            if node.name == "alienShip" {
                if node.position.y <= losingPoint {
                    isGameOver = true
                    labelNode?.text = "You lose! :("
                    self.isPaused = true
                    break
                }
            }
        }
        
        timeUntilSpeedUp -= 1
        if timeUntilSpeedUp == 0 {
            self.speed += 1
            timeUntilSpeedUp = 120
        }
        
        timeUntilAlienFires -= 1
        if timeUntilAlienFires == 0 {
            spawnAlienBullet()
            timeUntilAlienFires = 60
        }
    }
}

// Ended at 10:43 6-4-2022
