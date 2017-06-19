//
//  AddSongVC.swift
//  XCSync
//
//  Created by Bradley Klemick on 6/10/17.
//  Copyright © 2017 BradzTech. All rights reserved.
//

import UIKit
import MediaPlayer

class AddSongVC: UIViewController {
    @IBOutlet weak var motivationControl: UISegmentedControl!
    @IBOutlet weak var lblSongName: UILabel!
    var songsToAdd = [MPMediaItem]()
    var songs = [RunSong]()
    var csong: RunSong?
    var numProcessed = 0
    
    override func viewDidLoad() {
        let font = UIFont.systemFont(ofSize: 32)
        motivationControl.setTitleTextAttributes([NSFontAttributeName: font], for: .normal)
        
        for mediaItem in self.songsToAdd {
            let song = RunSong(assetUrl: mediaItem.assetURL!)
            var songTitle = ""
            if let title = mediaItem.title {
                songTitle = title
            }
            if let artist = mediaItem.artist {
                songTitle += " | " + artist
            }
            song.name = songTitle
            songs.append(song)
        }
        DispatchQueue.global(qos: .userInitiated).async {
            let songsToProcess = self.songs
            for song in songsToProcess {
                song.calcSpecs()
                self.numProcessed += 1
            }
        }
        askNextSong()
    }
    
    private func askNextSong() {
        if let song = songs.first {
            csong = song
            motivationControl.selectedSegmentIndex = UISegmentedControlNoSegment
            lblSongName.text = song.name
        } else {
            AppDelegate.saveContext()
            dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func ratingSelected(_ sender: UISegmentedControl) {
        if let song = csong {
            while self.numProcessed < 1 {
                sleep(1)
            }
            song.motivationRating = Int16(sender.selectedSegmentIndex + 1)
            if song.bpm == 0 {
                AppDelegate.moc.delete(song)
            }
            songs.remove(at: 0)
            numProcessed -= 1
            askNextSong()
        }
    }
}
