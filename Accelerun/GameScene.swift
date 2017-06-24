//
//  GameScene.swift
//  Accelerun
//
//  Created by Bradley Klemick on 6/22/17.
//  Copyright © 2017 BradzTech. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    var lastFlash = 0
    var feet = [SKSpriteNode]()
    var emitters = [SKEmitterNode]()
    
    override func didMove(to view: SKView) {
        for i in 0..<2 {
            let foot = SKSpriteNode(imageNamed: "rightFoot")
            foot.position = CGPoint(x: view.bounds.midX + (CGFloat(i) * 2 - 1) * 64, y: 300)
            foot.zPosition = 3
            if i == 0 {
                foot.xScale *= -1
            }
            addChild(foot)
            feet.append(foot)
            
            let emitter = SKEmitterNode(fileNamed: "MyParticle")!
            emitter.position = foot.position
            addChild(emitter)
            emitters.append(emitter)
        }
    }
    
    // Run on background thread
    func flashFoot() {
        DispatchQueue.main.async {
            self.emitters[self.lastFlash].resetSimulation()
        }
        //usleep(10000)
        DispatchQueue.main.async {
            self.feet[self.lastFlash].run(SKAction.colorize(with: UIColor.yellow, colorBlendFactor: 1.0, duration: 0.0))
            self.feet[self.lastFlash].run(SKAction.colorize(with: UIColor.black, colorBlendFactor: 1.0, duration: 0.5))
            self.lastFlash = (self.lastFlash + 1) % 2
        }
    }
}
