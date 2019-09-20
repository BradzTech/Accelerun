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
    private var _tFactor: Float = 1.0
    var cFolder: SongFolder?
    var cIndex: Int = 0
    private var _playing = false
    var scene: GameScene!
    
    // Dynamic properties
    var trueRatio: Float {
        get {
            return _trueRatio
        } set {
            var tFactor: Float = 1.0
            if newValue > 1.6 {
                tFactor /= 2
            } else if newValue < 0.8 {
                tFactor *= 2
            }
            _tFactor = tFactor
            _trueRatio = newValue * tFactor
        }
    }
    
    var playing: Bool {
        get {
            return _playing
        } set {
            _playing = newValue
            if _playing {
                if let _ = cSong as? SongApple {
                    musicPlayer.resume()
                } else {
                    musicPlayer.pause()
                    webView.resume()
                }
                playPauseBtn.setImage(UIImage(named: "btnPause"), for: .normal)
            } else {
                if let _ = cSong as? SongApple {
                    musicPlayer.pause()
                } else {
                    webView.pause()
                }
                playPauseBtn.setImage(UIImage(named: "btnPlay"), for: .normal)
            }
        }
    }
    
    var cSong: Song? {
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
        commandCenter.previousTrackCommand.addTarget(self, action:#selector(remotePrev(_:)))
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget(self, action:#selector(remoteNext(_:)))
        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget(self, action:#selector(changePlaybackPosition(_:)))
        let ytUrl = Bundle.main.url(forResource: "yt", withExtension: "html")!
        let ytHtml = try! String(contentsOf: ytUrl, encoding: .utf8)
        webView.loadHTMLString(ytHtml, baseURL: URL(string: "https://bradztech.com/"))
        //webView.load(URLRequest(url: URL(string: "https://bradztech.com/c/ios/accelerun/yt.html")!))
        webView.navigationDelegate = self
        
        DispatchQueue.global(qos: .default).async {
            while true {
                var sleepTime: Double = 0
                if let _ = self.cSong as? SongApple {
                    let msToNextBeat = self.musicPlayer.getMsToNextBeat()
                    if msToNextBeat > 0 {
                        sleepTime = (msToNextBeat - 10)
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
                            sleepTime = Double((song.beatFingerprint[i] - cur) / self.trueRatio * 1000) + 60
                        } else {
                            DispatchQueue.main.async {
                                self.btnNext()
                            }
                        }
                    }
                }
                // If we are doubled song speed, also half the step speed by adding a beat
                let beatTime = 60000 / Double(self.targetTempo)
                if self._tFactor > 1 {
                    sleepTime += beatTime
                }
                // Wait and then make the beat animation
                if sleepTime > 0 && sleepTime < 2500 {
                    usleep(useconds_t(sleepTime * 1000))
                    self.flashDot()
                }
                // If we are halved song speed, do two steps
                if self._tFactor < 1 {
                    usleep(useconds_t((beatTime - 20) * 1000))
                    self.flashDot()
                }
                usleep(33333)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if cFolder == nil {
            btnMusic(true)
        }
    }
    
    // IBActions
    
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
    
    @IBAction func btnPrev(_ sender: Any? = nil) {
        _ = remotePrev()
    }
    
    @IBAction func btnNext(_ sender: Any? = nil) {
        _ = remoteNext()
    }
    
    @IBAction func btnPlayPause(_ sender: Any) {
        if cFolder == nil {
            btnMusic(true)
            return
        }
        playing = !playing
        upTempo()
    }
    
    @IBAction func btnMusic(_ sender: Any) {
        performSegue(withIdentifier: "toNav", sender: nil)
    }
    
    // Remote control delegate methods
    
    @objc func remotePrev(_ sender: Any? = nil) -> MPRemoteCommandHandlerStatus {
        if let folder = cFolder {
            cIndex -= 1
            if cIndex < 0 {
                cIndex += folder.numSongs()
            }
            play(folder: folder, index: cIndex)
            return MPRemoteCommandHandlerStatus.success
        }
        return MPRemoteCommandHandlerStatus.noActionableNowPlayingItem
    }
    
    @objc func remoteNext(_ sender: Any? = nil) -> MPRemoteCommandHandlerStatus {
        if let folder = cFolder {
            cIndex = (cIndex + 1) % folder.numSongs()
            play(folder: folder, index: cIndex)
            return MPRemoteCommandHandlerStatus.success
        }
        return MPRemoteCommandHandlerStatus.noActionableNowPlayingItem
    }
    
    @objc func remotePlay(_ sender: Any? = nil) -> MPRemoteCommandHandlerStatus {
        playing = true
        upTempo()
        return MPRemoteCommandHandlerStatus.success
    }
    
    @objc func remotePause(_ sender: Any? = nil) -> MPRemoteCommandHandlerStatus {
        playing = false
        upTempo()
        return MPRemoteCommandHandlerStatus.success
    }
    
    @objc func changePlaybackPosition(_ event: MPChangePlaybackPositionCommandEvent) -> MPRemoteCommandHandlerStatus {
        musicPlayer.setPosition(event.positionTime * Double(musicPlayer.getCurrentFactor()))
        MPNowPlayingInfoCenter.default().nowPlayingInfo![MPNowPlayingInfoPropertyElapsedPlaybackTime] = event.positionTime
        return MPRemoteCommandHandlerStatus.success
    }
    
    // Methods
    
    func play(folder: SongFolder, index: Int) {
        playing = false
        cFolder = folder
        cIndex = index
        if cSong == nil || !cSong!.CanPlay {
            btnNext()
            return
        }
        if let cSong = cSong as? SongApple {
            webView.pause()
            if !webView.isHidden {
                musicPlayer = AdvPlayer()
            }
            webView.isHidden = true
            cSong.playIn(advPlayer: musicPlayer)
        } else if let cSong = cSong as? SongYoutube {
            webView.isHidden = false
            cSong.playIn(webView: webView)
        }
        playing = true
        
        let lastTempo = UserDefaults.standard.integer(forKey: "lastTempo")
        if lastTempo == 0 {
            _ = remotePause()
            tutView.isHidden = false
            tutViewBack.isHidden = false
        } else {
            targetTempo = Float(lastTempo)
            upTempo()
        }
    }
    
    private var startData: UInt64 = 0
    public func upTempo() {
        scene.setEffectColor(tempo: targetTempo)
        lblTempo.text = "\(Int(targetTempo))"
        if let song = cSong as? SongYoutube {
            trueRatio = targetTempo / song.bpm
            lblSong.text = song.title
            webView.evaluateJavaScript("setPlaybackRate(\(trueRatio));", completionHandler: nil)
        } else if let song = cSong as? SongApple {
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
    
    func flashDot() {
        scene.flashFoot()
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
    
    // Pedometer
    
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
        _ = remotePlay()
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
