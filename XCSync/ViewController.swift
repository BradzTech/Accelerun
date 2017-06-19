//
//  ViewController.swift
//  XCSync
//
//  Created by Bradley Klemick on 6/9/17.
//  Copyright © 2017 BradzTech. All rights reserved.
//

import UIKit
import CoreLocation
import MediaPlayer
import CoreData
import CoreMotion
import HealthKit

class ViewController: UIViewController, CLLocationManagerDelegate, MPMediaPickerControllerDelegate {
    static var inst: ViewController!
    var locMan: CLLocationManager!
    private var musicPlayer: AdvPlayer!
    var targetTempo: Float = 155.0
    var ttFactor: Float = 1
    var csong: RunSong?
    var songs = [RunSong]()
    @IBOutlet weak var lblTempo: UILabel!
    var pedometer: CMPedometer!
    var stepCadence: Float = 0.0
    var runPoints = [RunPoint]()
    @IBOutlet weak var lblTmp: UILabel!
    @IBOutlet weak var circleView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ViewController.inst = self
        locMan = CLLocationManager()
        locMan.delegate = self
        locMan.requestAlwaysAuthorization()
        locMan.activityType = .fitness
        locMan.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        if CLLocationManager.authorizationStatus() == .authorizedAlways {
            locMan.startUpdatingLocation()
        }
        musicPlayer = AdvPlayer()
        
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
        
        circleView.layer.cornerRadius = circleView.layer.bounds.height / 2
        circleView.layer.borderColor = UIColor(white: 1.0, alpha: 0.9).cgColor
        circleView.layer.borderWidth = 2.0
        DispatchQueue.global(qos: .userInitiated).async {
            while true {
                var msSinceLastBeat = self.musicPlayer.getMsSinceLastBeat()
                if self.ttFactor != 1 {
                    msSinceLastBeat = 0
                }
                let msToNextBeat = (60000 / Double(self.targetTempo * self.ttFactor) - msSinceLastBeat) * Double(self.ttFactor)
                if msToNextBeat >= 0 && msToNextBeat.isFinite {
                    usleep(useconds_t(msToNextBeat * 1000))
                    DispatchQueue.main.async {
                        self.flashDot()
                    }
                } else {
                    usleep(100000)
                }
            }
        }
    }
    
    @IBAction func addBtn() {
        let pickerController = MPMediaPickerController(mediaTypes: .music)
        pickerController.allowsPickingMultipleItems = true
        pickerController.delegate = self
        present(pickerController, animated: true, completion: nil)
    }
    
    func play(song: RunSong) {
        csong = song
        song.playIn(advPlayer: musicPlayer)
        upTempo()
    }
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        mediaPicker.dismiss(animated: true, completion: nil)
    }
    
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        var songsLeftToAdd = [MPMediaItem]()
        for song in mediaItemCollection.items {
            if song.assetURL != nil {
                songsLeftToAdd.append(song)
            }
        }
        mediaPicker.dismiss(animated: true, completion: nil)
        let addSongVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AddSongVC") as! AddSongVC
        addSongVC.songsToAdd = songsLeftToAdd
        present(addSongVC, animated: true, completion: nil)
    }
    
    private func upTempo() {
        if let song = csong {
            let bpm = song.bpm
            var ttf: Float = 1
            if targetTempo > bpm * 5 / 3 {
                ttf /= 2
            } else if targetTempo < bpm * 5 / 6 {
                ttf *= 2
            }
            ttFactor = ttf
            let newTempo = targetTempo * ttFactor / bpm
            musicPlayer.setTempo(newTempo)
            lblTempo.text = "\(targetTempo)"
            lblTempo.textColor = UIColor(hue: CGFloat(1.07 - (newTempo) * 0.7).remainder(dividingBy: 1.0), saturation: 1.0, brightness: 1.0, alpha: 1.0)
        }
    }
    @IBAction func tempoSliderChanged(_ sender: UISlider) {
        targetTempo = sender.value
        upTempo()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            locMan.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let loc = locations.last {
            runPoints.append(RunPoint(location: loc, stepsPerMinute: stepCadence))
            lblTmp.text = "\(runPoints.count)\n\(26.8224 / (loc.speed + 0.01))\n\(stepCadence)"
            AppDelegate.saveContext()
        }
    }
    
    func flashDot() {
        circleView.backgroundColor = UIColor.cyan
        
        UIView.animate(withDuration: TimeInterval(60 / targetTempo - 0.05), delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: {
            self.circleView.backgroundColor = UIColor.black
        }, completion: nil)
    }
    
}

