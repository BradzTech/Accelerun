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
import WebKit

class ViewController: UIViewController {
    // Internal/static properties
    static var inst: ViewController!
    private var musicPlayer: AdvPlayer!
    var targetTempo: Float = 0.0
    private var _trueRatio: Float = 1.0
    var cFolder: SongFolder?
    var cIndex: Int = 0
    private var _playing = false
    var scene: GameScene!
    
    // Dynamic properties
    var trueRatio: Float {
        get {
            return _trueRatio
        } set {
            var tr = newValue
            if tr > 1.6 {
                tr /= 2
            } else if tr < 0.8 {
                tr *= 2
            }
            _trueRatio = newValue
        }
    }
    
    var playing: Bool {
        get {
            return _playing
        } set {
            _playing = newValue
            if _playing {
                if let _ = cSong as? Song {
                    musicPlayer.resume()
                } else {
                    musicPlayer.pause()
                    webView.resume()
                }
                playPauseBtn.setImage(UIImage(named: "btnPause"), for: .normal)
            } else {
                if let _ = cSong as? Song {
                    musicPlayer.pause()
                } else {
                    webView.pause()
                }
                playPauseBtn.setImage(UIImage(named: "btnPlay"), for: .normal)
            }
        }
    }
    
    var cSong: SongItem? {
        if let folder = cFolder {
            return folder.at(index: cIndex)
        }
        return nil
    }
    
    // Outlet properties
    @IBOutlet weak var circleView: UIView!
    @IBOutlet weak var lblTempo: UILabel!
    @IBOutlet weak var playPauseBtn: UIButton!
    @IBOutlet weak var lblSong: UILabel!
    @IBOutlet weak var tutView: UIView!
    @IBOutlet weak var tutViewBack: UIView!
    @IBOutlet weak var lblMotionAccess: UILabel!
    @IBOutlet weak var lblDetecting: UILabel!
    @IBOutlet weak var webView: YTWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ViewController.inst = self
        musicPlayer = AdvPlayer()
        BackgroundAnalyzer.rescan()
        startPedometer()
        webView.scrollView.contentInset = UIEdgeInsets.zero
        
        DispatchQueue.global(qos: .default).async {
            while true {
                if let _ = self.cSong as? Song {
                    let msToNextBeat = self.musicPlayer.getMsToNextBeat()
                    if (msToNextBeat > 0) {
                        let sleepTime = msToNextBeat * 1000 / Double(self.trueRatio) - 5000
                        if sleepTime > 0 {
                            usleep(useconds_t(sleepTime))
                        }
                        self.flashDot()
                    }
                } else if let song = self.cSong as? SongYoutube {
                    if self.playing {
                        let cur = Float(self.webView.getCurrentTime())
                        var i = 0
                        let len = song.beatFingerprint.count
                        while i < len && song.beatFingerprint[i] < cur {
                            i += 1
                        }
                        if i < len {
                            let sleepTime = UInt32((song.beatFingerprint[i] - cur) / self.trueRatio * 1000000)
                            if sleepTime > 0 && sleepTime < 3000000 {
                                usleep(sleepTime)
                                self.flashDot()
                                usleep(40000)
                            }
                        } else {
                            DispatchQueue.main.async {
                                self.btnNext()
                            }
                        }
                    }
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
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget(self, action:#selector(remotePause(_:)))
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget(self, action:#selector(remotePlay(_:)))
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget(self, action:#selector(btnPrev(_:)))
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget(self, action:#selector(btnNext(_:)))
        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget(self, action:#selector(changePlaybackPosition(_:)))
        webView.load(URLRequest(url: URL(string: "https://bradztech.com/c/ios/accelerun/yt.html")!))
        webView.navigationDelegate = self
    }
    
    var initLoad = true
    override func viewDidAppear(_ animated: Bool) {
        if initLoad {
            initLoad = false
            btnMusic(true)
        }
    }
    
    func play(folder: SongFolder, index: Int) {
        playing = false
        cFolder = folder
        cIndex = index
        if let cSong = cSong as? Song {
            webView.isHidden = true
            cSong.playIn(advPlayer: musicPlayer)
        } else if let cSong = cSong as? SongYoutube {
            webView.isHidden = false
            cSong.playIn(webView: webView)
        }
        playing = true
        
        let lastTempo = UserDefaults.standard.integer(forKey: "lastTempo")
        if lastTempo == 0 {
            remotePause()
            tutView.isHidden = false
            tutViewBack.isHidden = false
        } else {
            targetTempo = Float(lastTempo)
            upTempo()
        }
    }
    
    public func upTempo() {
        scene.setEffectColor(tempo: targetTempo)
        lblTempo.text = "\(Int(targetTempo))"
        if let song = cSong as? SongYoutube {
            trueRatio = targetTempo / song.bpm
            lblSong.text = song.title
            webView.evaluateJavaScript("setPlaybackRate(\(trueRatio));", completionHandler: nil)
        } else if let song = cSong as? Song {
            trueRatio = targetTempo / song.bpm
            lblSong.text = song.title
            musicPlayer.setRatio(trueRatio)
            MPNowPlayingInfoCenter.default().nowPlayingInfo = [
                MPMediaItemPropertyTitle: song.title,
                MPMediaItemPropertyPlaybackDuration: Double(song.seconds / musicPlayer.getCurrentFactor()),
                MPNowPlayingInfoPropertyPlaybackRate: NSNumber(floatLiteral: playing ? 1.0: 0.0),
                MPNowPlayingInfoPropertyElapsedPlaybackTime: musicPlayer.getPosition() / musicPlayer.getCurrentFactor()
            ]
        }
        if targetTempo != 0 {
            UserDefaults.standard.set(Int(floor(targetTempo)), forKey: "lastTempo")
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
                    usleep(550000)
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
                    sleep(1)
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
    
    @IBAction func btnPrev(_ sender: Any? = nil) {
        if let folder = cFolder {
            cIndex -= 1
            if cIndex < 0 {
                cIndex += folder.numSongs()
            }
            play(folder: folder, index: cIndex)
        }
    }
    
    @IBAction func btnNext(_ sender: Any? = nil) {
        if let folder = cFolder {
            cIndex = (cIndex + 1) % folder.numSongs()
            play(folder: folder, index: cIndex)
        }
    }
    
    @objc func remotePlay(_ sender: Any? = nil) {
        playing = true
        upTempo()
    }
    
    @objc func remotePause(_ sender: Any? = nil) {
        playing = false
        upTempo()
    }
    
    @IBAction func btnPlayPause(_ sender: Any) {
        playing = !playing
        upTempo()
    }
    
    @objc func changePlaybackPosition(_ event: MPChangePlaybackPositionCommandEvent) {
        musicPlayer.setPosition(event.positionTime * Double(musicPlayer.getCurrentFactor()));
        MPNowPlayingInfoCenter.default().nowPlayingInfo![MPNowPlayingInfoPropertyElapsedPlaybackTime] = event.positionTime
    }
    
    @IBAction func btnMusic(_ sender: Any) {
        performSegue(withIdentifier: "toNav", sender: nil)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @objc func eof() {
        DispatchQueue.global(qos: .default).async {
            DispatchQueue.main.async {
                self.btnNext()
            }
        }
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
                        self._stepCadence = Float(truncating: cc) * 60
                        self.upPedometer()
                    }
                })
                pedometer.startEventUpdates(handler: {(pedoEvent, error) in
                    if let event = pedoEvent {
                        self._stepActive = event.type != CMPedometerEventType.pause
                        self.upPedometer()
                    }
                })
            }
        }
    }
    private func upPedometer() {
        DispatchQueue.main.async {
            self.lblMotionAccess.isHidden = true
            self.lblDetecting.isHidden = false
            let spm = self.stepsPerMinute
            if spm > 0.0 && !self.tutView.isHidden {
                self.targetTempo = floor(spm)
                self.finishTut()
            }
        }
        self.scene?.setEmitterStrength(Int(self.stepsPerMinute))
    }
    
    @IBAction func finishTut() {
        if targetTempo == 0.0 {
            targetTempo = 155.0
        }
        tutView.isHidden = true
        tutViewBack.isHidden = true
        remotePlay()
    }
}

extension ViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated  {
            if let url = navigationAction.request.url,
                UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        } else {
            decisionHandler(.allow)
        }
    }
}

@objc class VCBridge: NSObject {
    @objc public static func eof() {
        ViewController.inst.eof()
    }
}
