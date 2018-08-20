//
//  GameViewController.swift
//  Breaker
//
//  Created by gakki's vi~ on 2018/7/5.
//  Copyright © 2018年 zhangyw@yhyvr.com. All rights reserved.
//

import UIKit
import SceneKit

enum ColliderType: Int {
    case ball       = 0b0001
    case barrier    = 0b0010
    case brick      = 0b0100
    case paddle     = 0b1000
}

class GameViewController: UIViewController {
    
    var scnView: SCNView!
    var scnScene: SCNScene!
    var game = GameHelper.sharedInstance
    var horizontalCameraNode: SCNNode!
    var verticalCameraNode: SCNNode!
    var ballNode: SCNNode!
    var panddleNode: SCNNode!
    var floorNode: SCNNode!
    var lastContactNode: SCNNode!
    
    var touchx: CGFloat = 0
    var paddleX: Float = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        setupScene()
        setupNodes()
        setupSounds()
    }
    
    func setupScene() {
        scnView = (self.view as! SCNView)
        scnView.delegate = self
        scnScene = SCNScene(named: "Breaker.scnassets/Scenes/Game.scn")
        scnView.scene = scnScene
        scnScene.physicsWorld.contactDelegate = self
    }
    
    func setupNodes() {
        scnScene.rootNode.addChildNode(game.hudNode)
        horizontalCameraNode = scnScene.rootNode.childNode(withName: "HorizontalCamera", recursively: true)!
        verticalCameraNode = scnScene.rootNode.childNode(withName: "VerticalCamera", recursively: true)!
        
        ballNode = scnScene.rootNode.childNode(withName: "Ball", recursively: true)!
        panddleNode = scnScene.rootNode.childNode(withName: "Paddle", recursively: true)!
        ballNode.physicsBody?.contactTestBitMask = ColliderType.barrier.rawValue | ColliderType.brick.rawValue | ColliderType.paddle.rawValue
        
        floorNode = scnScene.rootNode.childNode(withName: "Floor",
                                        recursively: true)!
        verticalCameraNode.constraints = [SCNLookAtConstraint(target: floorNode)]
        horizontalCameraNode.constraints = [SCNLookAtConstraint(target: floorNode)]
    }
    
    func setupSounds() {
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: scnView)
            touchx = location.x
            paddleX = panddleNode.position.x
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: scnView)
            panddleNode.position.x = paddleX + Float((location.x - touchx) * 0.1)
            if panddleNode.position.x > 4.5 {
                panddleNode.position.x = 4.5
            } else if panddleNode.position.x < -4.5 {
                panddleNode.position.x = -4.5
            }
            verticalCameraNode.position.x = panddleNode.position.x
            horizontalCameraNode.position.x = panddleNode.position.x
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        let deviceOrientation = UIDevice.current.orientation
        switch deviceOrientation {
        case .portrait:
            scnView.pointOfView = verticalCameraNode
        default:
            scnView.pointOfView = horizontalCameraNode
        }
        
    }
    
    override var shouldAutorotate: Bool { return true }
    override var prefersStatusBarHidden: Bool { return true }
}

extension GameViewController: SCNSceneRendererDelegate {
    func renderer(_ renderer: SCNSceneRenderer,
                  updateAtTime time: TimeInterval) {
        game.updateHUD()
    }
}

extension GameViewController: SCNPhysicsContactDelegate {
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        var contactNode: SCNNode!
        if contact.nodeA.name == "Ball" {
            contactNode = contact.nodeB
        } else {
            contactNode = contact.nodeA
        }
        
        if lastContactNode != nil && lastContactNode == contactNode {
            lastContactNode = contactNode
            return
        }
        lastContactNode = contactNode
        
        if contactNode.physicsBody?.categoryBitMask == ColliderType.barrier.rawValue {
            if contactNode.name == "Bottom" {
                game.lives -= 1
                if game.lives == 0 {
                    game.saveState()
                    game.reset()
                }
            }
        }
        
        if contactNode.physicsBody?.categoryBitMask == ColliderType.brick.rawValue {
            game.score += 1
            contactNode.isHidden = true
            contactNode.runAction(SCNAction.waitForDurationThenRunBlock(duration: 120, block: { (node: SCNNode!) in
                node.isHidden = false
            }))
        }
        
        if contactNode.physicsBody?.categoryBitMask == ColliderType.paddle.rawValue {
            if contactNode.name == "Left" {
                ballNode.physicsBody?.velocity.xzAngle -= convertToRadians(angle: 20)
            }
            if contactNode.name == "Right" {
                ballNode.physicsBody?.velocity.xzAngle += convertToRadians(angle: 20)
            }
        }
        
        ballNode.physicsBody?.velocity.length = 5.0
    }
}
