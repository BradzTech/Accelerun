//
//  RunSong.swift
//  Accelerun
//
//  Created by Bradley Klemick on 6/10/17.
//  Copyright © 2017 BradzTech. All rights reserved.
//

import CoreData
import MediaPlayer

class Song: SongItem {
    @NSManaged var url: String
    @NSManaged var bpm: Float
    @NSManaged var beatStartMs: Float
    @NSManaged var peakDb: Float
    @NSManaged var seconds: Float
    
    var Url: URL {
        return URL(string: url)!
        //return URL(string: URL(string: url)!.path)!
    }
    
    init(assetUrl: URL, title: String, seconds: Float) {
        super.init(entity: NSEntityDescription.entity(forEntityName: "Song", in: AppDelegate.moc)!, insertInto: AppDelegate.moc)
        url = assetUrl.absoluteString
        self.title = title
        self.seconds = seconds
    }
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    func calcSpecs() {
        let analyzer = BPMDetector()
        analyzer.calc(Url)
        bpm = analyzer.getBpm()
        beatStartMs = analyzer.getBeatStartMs()
        peakDb = analyzer.getPeakDb()
        if bpm == 0 {
            print("Error on song \(title)!")
        }
    }
    
    func playIn(advPlayer: AdvPlayer) {
        if bpm == 0 {
            DispatchQueue.global(qos: .userInitiated).async {
                self.calcSpecs()
                DispatchQueue.main.async {
                    self.finishPlay(advPlayer: advPlayer)
                }
            }
        } else {
            finishPlay(advPlayer: advPlayer)
        }
    }
    
    private func finishPlay(advPlayer: AdvPlayer) {
        advPlayer.play(Url)
        advPlayer.setOrigBpm(bpm, beatStartMs: beatStartMs)
        advPlayer.setVolume(powf(2, peakDb / -3)) // Normalization!
    }
    
    static func multicloudResults() -> [Song]? {
        let sharedUD = UserDefaults(suiteName: "group.com.bradztech")!
        if let mcDict = sharedUD.dictionary(forKey: "multicloud-local") as? [String: String],
            let containerUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.bradztech") {
            let mcUrl = containerUrl.appendingPathComponent("multicloud")
            if FileManager.default.fileExists(atPath: mcUrl.path) && false {
                var songs = [Song]()
                for (title, uid) in mcDict {
                    let preFetch = NSFetchRequest<Song>(entityName: "Song")
                    let assetUrl = URL(string: mcUrl.appendingPathComponent(uid + "-meow.m4a").path)!
                    preFetch.predicate = NSPredicate(format: "url = %@", assetUrl.path)
                    var theSong: Song?
                    do {
                        let fetchRes = try AppDelegate.moc.fetch(preFetch)
                        theSong = fetchRes.first
                    } catch {}
                    if theSong == nil {
                        theSong = Song(assetUrl: assetUrl, title: title, seconds: 240)
                    }
                    songs.append(theSong!)
                }
                AppDelegate.saveContext()
                return songs
            }
        }
        return nil
    }
}

class BackgroundAnalyzer {
    static var active: Bool = false
    
    static func rescan() {
        if !active {
            active = true
            let songFetch = NSFetchRequest<Song>(entityName: "Song")
            songFetch.predicate = NSPredicate(format: "bpm == 0")
            do {
                let songs = try AppDelegate.moc.fetch(songFetch)
                DispatchQueue.global(qos: .utility).async {
                    for song in songs {
                        song.calcSpecs()
                        AppDelegate.saveContext()
                    }
                }
            } catch {}
            active = false
        }
    }
}
