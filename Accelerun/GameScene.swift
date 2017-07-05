//
//  GameScene.swift
//  Accelerun
//
//  Created by Bradley Klemick on 6/22/17.
//  Copyright © 2017 BradzTech. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    private var lastFlash = 0
    private var feet = [SKSpriteNode]()
    private var emitters = [SKEmitterNode]()
    private var effectColor = UIColor.yellow
    private var emitterStrength: Int = 100
    private var footScale: CGFloat = 0.88
    
    override func didMove(to view: SKView) {
        for i in 0..<2 {
            let foot = SKSpriteNode(imageNamed: "rightFoot")
            foot.position = CGPoint(x: view.bounds.midX + (CGFloat(i) * 2 - 1) * (view.bounds.width * 0.17), y: view.bounds.midY)
            foot.xScale = footScale
            foot.yScale = foot.xScale
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
            if self.emitterStrength != 0 {
                self.emitters[self.lastFlash].particleColor = self.effectColor
                self.emitters[self.lastFlash].numParticlesToEmit = self.emitterStrength
                self.emitters[self.lastFlash].resetSimulation()
            }
        }
        //usleep(10000)
        DispatchQueue.main.async {
            let lf = self.lastFlash
            let foot = self.feet[lf]
            let scaleFactor: CGFloat = 0.85
            let footScale = self.footScale * (lf == 1 ? 1 : -1)
            foot.run(SKAction.colorize(with: self.effectColor, colorBlendFactor: 1.0, duration: 0.0))
            foot.run(SKAction.scaleX(to: footScale / scaleFactor, y: self.footScale / scaleFactor, duration: 0.0))
            foot.run(SKAction.colorize(with: UIColor.black, colorBlendFactor: 1.0, duration: 0.5))
            foot.run(SKAction.scaleX(to: footScale, y: self.footScale, duration: 0.3))
            self.lastFlash = (self.lastFlash + 1) % 2
        }
    }
    
    func setEffectColor(tempo: Float) {
        if tempo >= 105 && tempo <= 210 {
            effectColor = UIColor(hue: (1 - ((CGFloat(tempo) - 105) / 105)) / 3, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        }
    }
    
    func setEmitterStrength(_ strength: Int) {
        emitterStrength = strength
    }
}
