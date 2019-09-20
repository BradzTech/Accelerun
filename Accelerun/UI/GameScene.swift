//
//  GameScene.swift
//  Accelerun
//
//  Created by Bradley Klemick on 6/22/17.
//  Copyright © 2017 BradzTech. All rights reserved.
//

import SpriteKit
import CoreHaptics

class GameScene: SKScene {
    private var lastFlash = 0
    private var feet = [SKSpriteNode]()
    private var emitters = [SKEmitterNode]()
    private var effectColor = UIColor.yellow
    private var emitterStrength: Int = 100
    private var footScale: CGFloat = 0.88
    private var animTime: Double = 0.5
    private var feedbackGenerator: UIImpactFeedbackGenerator?
    
    // Initialize this SpriteKit Scene
    override func didMove(to view: SKView) {
        for i in 0..<2 {
            let foot = SKSpriteNode(imageNamed: "rightFoot")
            foot.position = CGPoint(x: view.bounds.midX + (CGFloat(i) * 2 - 1) * (view.bounds.width * 0.17), y: view.bounds.midY)
            foot.xScale = footScale
            foot.yScale = foot.xScale
            foot.zPosition = 3
            foot.run(SKAction.colorize(with: UIColor.black, colorBlendFactor: 1.0, duration: 0.0))
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
        
        // Initialize the haptics if OS supports
        if #available(iOS 13.0, *) {
            GameHaptics.inst = GameHaptics()
        }
    }
    
    // Flash a foot, including all effects (particles, haptics, etc.)
    // Invoked from a background thread
    func flashFoot() {
        DispatchQueue.main.async {
            // Fire particle emitter behind foot
            if self.emitterStrength != 0 {
                self.emitters[self.lastFlash].particleColor = self.effectColor
                self.emitters[self.lastFlash].numParticlesToEmit = self.emitterStrength
                self.emitters[self.lastFlash].resetSimulation()
            }
            
            // Fire haptic if available
            if #available(iOS 13.0, *) {
                if let haptics = GameHaptics.inst {
                    haptics.tap()
                }
            }
            
            // Flash foot
            let lf = self.lastFlash
            let foot = self.feet[lf]
            let scaleFactor: CGFloat = 5 / 6
            let footScale = self.footScale * (lf == 1 ? 1 : -1)
            foot.run(SKAction.colorize(with: self.effectColor, colorBlendFactor: 1.0, duration: 0.0))
            foot.run(SKAction.scaleX(to: footScale / scaleFactor, y: self.footScale / scaleFactor, duration: 0.0))
            foot.run(SKAction.colorize(with: UIColor.black, colorBlendFactor: 1.0, duration: 0.5))
            foot.run(SKAction.scaleX(to: footScale, y: self.footScale, duration: self.animTime))
            self.lastFlash = (self.lastFlash + 1) % 2
        }
    }
    
    // Set the color of both the feet and the emitters based on tempo
    func setEffectColor(tempo: Float) {
        if tempo >= 105 && tempo <= 210 {
            var hue: CGFloat = (CGFloat(tempo) - 100) / 105 / 2.7
            if tempo > 155 {
                hue += (CGFloat(tempo) - 155) / 450
            }
            effectColor = UIColor(hue: hue, saturation: 0.9, brightness: 1.0, alpha: 1.0)
            animTime = 60 / Double(tempo)
        }
    }
    
    // Set the strength of the particle emitters
    func setEmitterStrength(_ strength: Int) {
        emitterStrength = strength
    }

    // Code for haptics, encapsulated to be skipped if OS doesn't support
    @available(iOS 13.0, *)
    private class GameHaptics {
        public static var inst: GameHaptics!
        private var engine: CHHapticEngine
        private var player: CHHapticPatternPlayer
        
        init?() {
            let tapEvent = CHHapticEvent(eventType: .hapticTransient, parameters: [CHHapticEventParameter(parameterID: CHHapticEvent.ParameterID.hapticSharpness, value: 0.3), CHHapticEventParameter(parameterID: CHHapticEvent.ParameterID.hapticIntensity, value: 0.45)], relativeTime: 0.001)
            do {
                let hapticPattern = try CHHapticPattern(events: [tapEvent], parameters: [])
                engine = try CHHapticEngine()
                player = try engine.makePlayer(with: hapticPattern)
            } catch {
                return nil
            }
        }
        
        public func tap() {
            try? engine.start()
            try? player.start(atTime: 0)
        }
        
        public func stopEngine() {
            engine.stop(completionHandler: nil)
        }
    }
}
