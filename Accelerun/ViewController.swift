//
//  ViewController.swift
//  Accelerun
//
//  Created by Bradley Klemick on 6/9/17.
//  Copyright © 2017 BradzTech. All rights reserved.
//

import UIKit
import MediaPlayer
import CoreData
import CoreMotion
import SpriteKit

class ViewController: UIViewController {
    static var inst: ViewController!
    private var musicPlayer: AdvPlayer!
    var targetTempo: Float = 155.0
    var currentTempo: Float = 1
    var ttFactor: Float = 1
    var cFolder: SongFolder?
    var cIndex: Int = 0
    private var _playing = false
    var scene: GameScene!
    var playing: Bool {
        get {
            return _playing
        } set {
            _playing = newValue
            if _playing {
                musicPlayer.resume()
                playPauseBtn.setImage(UIImage(named: "btnPause"), for: .normal)
            } else {
                musicPlayer.pause()
                playPauseBtn.setImage(UIImage(named: "btnPlay"), for: .normal)
            }
        }
    }
    
    var cSong: Song? {
        if let folder = cFolder {
            return folder.at(index: cIndex) as? Song
        }
        return nil
    }
    
    @IBOutlet weak var circleView: UIView!
    @IBOutlet weak var lblTempo: UILabel!
    @IBOutlet weak var playPauseBtn: UIButton!
    @IBOutlet weak var lblSong: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ViewController.inst = self
        musicPlayer = AdvPlayer()
        BackgroundAnalyzer.rescan()
        startPedometer()
        
        DispatchQueue.global(qos: .userInitiated).async {
            while true {
                let msToNextBeat = self.musicPlayer.getMsToNextBeat()
                if (msToNextBeat > 0) {
                    let sleepTime = msToNextBeat * 1000 / Double(self.currentTempo) - 5000
                    if sleepTime > 0 {
                        usleep(useconds_t(sleepTime))
                    }
                    self.flashDot()
                }
                usleep(40000)
            }
        }
        
        if let skView = circleView as? SKView {
            scene = GameScene()
            scene.scaleMode = .aspectFill
            scene.size = skView.bounds.size
            scene.backgroundColor = view.backgroundColor!
            skView.ignoresSiblingOrder = true
            skView.presentScene(scene)
        }
    }
    
    func play(folder: SongFolder, index: Int) {
        cFolder = folder
        cIndex = index
        cSong?.playIn(advPlayer: musicPlayer)
        upTempo()
        playing = true
    }
    
    private func upTempo() {
        musicPlayer.setTargetBpm(targetTempo)
        if let song = cSong {
            lblSong.text = song.title
            lblTempo.text = "\(Int(targetTempo))"
            scene.setEffectColor(tempo: targetTempo)
        }
    }
    
    private var processNextUp = true
    @IBAction func tempoUp(_ sender: Any) {
        if processNextUp {
            targetTempo += 5
            if targetTempo > 210 {
                targetTempo = 105
            }
            upTempo()
        }
        processNextUp = true
    }
    
    @IBAction func tempoDown(_ sender: Any) {
        if processNextUp {
            targetTempo -= 5
            if targetTempo < 105 {
                targetTempo = 210
            }
            upTempo()
        }
        processNextUp = true
    }
    
    @IBAction func tempoUpHold(_ sender: UIButton, forEvent event: UIEvent) {
        if let touch = event.allTouches?.first {
            DispatchQueue.global(qos: .default).async {
                while touch.phase != .cancelled && touch.phase != .ended {
                    usleep(1100000)
                    if touch.phase != .cancelled && touch.phase != .ended && self.targetTempo < 210 {
                        self.targetTempo += 1
                        self.processNextUp = false
                        DispatchQueue.main.async {
                            self.upTempo()
                        }
                    }
                }
            }
        }
    }
    @IBAction func tempoDownHold(_ sender: UIButton, forEvent event: UIEvent) {
        if let touch = event.allTouches?.first {
            DispatchQueue.global(qos: .default).async {
                while touch.phase != .cancelled && touch.phase != .ended {
                    usleep(1100000)
                    if touch.phase != .cancelled && touch.phase != .ended && self.targetTempo > 105 {
                        self.targetTempo -= 1
                        self.processNextUp = false
                        DispatchQueue.main.async {
                            self.upTempo()
                        }
                    }
                }
            }
        }
    }
    
    func flashDot() {
        scene.flashFoot()
    }
    
    @IBAction func btnPrev(_ sender: Any) {
        if let folder = cFolder {
            cIndex -= 1
            if cIndex < 0 {
                cIndex += folder.numSongs()
            }
            play(folder: folder, index: cIndex)
        }
    }
    
    @IBAction func btnNext(_ sender: Any) {
        if let folder = cFolder {
            cIndex = (cIndex + 1) % folder.numSongs()
            play(folder: folder, index: cIndex)
        }
    }
    
    @IBAction func btnPlayPause(_ sender: Any) {
        playing = !playing
    }
    
    @IBAction func btnMusic(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // Begin Pedometer
    private var pedometer: CMPedometer!
    private var _stepCadence: Float = 0.0
    private var _stepActive = true
    private var stepsPerMinute: Float {
        if _stepActive {
            return _stepCadence
        } else {
            return 0.0
        }
    }
    private func startPedometer() {
        if pedometer == nil {
            if CMPedometer.isPedometerEventTrackingAvailable() {
                pedometer = CMPedometer()
                pedometer.startUpdates(from: Date(), withHandler: {(pedoData, error) in
                    if let pd = pedoData,
                        let cc = pd.currentCadence {
                        self._stepCadence = Float(cc) * 60
                        self.upPedometer()
                    }
                })
                pedometer.startEventUpdates(handler: {(pedoEvent, error) in
                    if let event = pedoEvent {
                        self._stepActive = event.type != CMPedometerEventType.pause
                        self.upPedometer()
                    }
                })
            } else {
                print("MEOW")
            }
        }
    }
    private func upPedometer() {
        self.scene?.setEmitterStrength(Int(self.stepsPerMinute))
    }
}

