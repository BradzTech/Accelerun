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
    var pedometer: CMPedometer!
    var stepCadence: Float = 0.0
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
    
    @IBOutlet weak var lblTmp: UILabel!
    @IBOutlet weak var circleView: UIView!
    @IBOutlet weak var lblTempo: UILabel!
    @IBOutlet weak var playPauseBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ViewController.inst = self
        musicPlayer = AdvPlayer()
        BackgroundAnalyzer.rescan()
        
        pedometer = CMPedometer()
        pedometer.startUpdates(from: Date(), withHandler: {(pedoData, error) in
            if let pd = pedoData,
                let cc = pd.currentCadence {
                self.stepCadence = Float(cc) * 60
            }
        })
        pedometer.startEventUpdates(handler: {(pedoEvent, error) in
            if let event = pedoEvent {
                if event.type == CMPedometerEventType.pause {
                    self.stepCadence = 0
                }
            }
        })
        
        DispatchQueue.global(qos: .userInitiated).async {
            while true {
                let msToNextBeat = self.musicPlayer.getMsToNextBeat()
                if (msToNextBeat > 0) {
                    if let cSong = self.cSong {
                        let sleepTime = msToNextBeat * 1000 / Double(self.currentTempo)
                        if sleepTime > 0 {
                            usleep(useconds_t(sleepTime))
                        }
                        self.flashDot()
                    }
                }
                usleep(40000)
                /*if self.ttFactor != 1 {
                    msSinceLastBeat = 0
                }*/
                /*let msToNextBeat = (60000 / Double(self.targetTempo * self.ttFactor) - msSinceLastBeat) * Double(self.ttFactor)
                if msToNextBeat >= 0 && msToNextBeat.isFinite {
                    usleep(useconds_t(msToNextBeat * 1000))
                    self.flashDot()
                } else {
                    usleep(100000)
                }*/
            }
        }
        
        if let skView = circleView as? SKView {
            scene = GameScene()
            scene.scaleMode = .resizeFill
            print(AppDelegate.moc)
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
        if let song = cSong {
            let bpm = song.bpm
            var ttf: Float = 1
            if targetTempo > bpm * 5 / 3 {
                ttf /= 2
            } else if targetTempo < bpm * 5 / 6 {
                ttf *= 2
            }
            let ttFactor = ttf
            currentTempo = targetTempo * ttFactor / bpm
            musicPlayer.setTempo(currentTempo)
            lblTempo.text = "\(targetTempo)"
            lblTempo.textColor = UIColor(hue: CGFloat(1.07 - (currentTempo) * 0.7).remainder(dividingBy: 1.0), saturation: 1.0, brightness: 1.0, alpha: 1.0)
        }
    }
    @IBAction func tempoSliderChanged(_ sender: UISlider) {
        targetTempo = sender.value
        upTempo()
    }
    
    func flashDot() {
        /*circleView.backgroundColor = UIColor.cyan
        
        UIView.animate(withDuration: TimeInterval(60 / targetTempo - 0.05), delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
            self.circleView.backgroundColor = UIColor.black
        }, completion: nil)*/
        scene.flashFoot()
    }
    
    @IBAction func btnPrev(_ sender: Any) {
        if let folder = cFolder {
            cIndex = (cIndex - 1) % folder.numSongs()
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
}
