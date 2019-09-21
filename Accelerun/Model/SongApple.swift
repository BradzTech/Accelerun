//
//  RunSong.swift
//  Accelerun
//
//  Created by Bradley Klemick on 6/10/17.
//  Copyright © 2017 BradzTech. All rights reserved.
//

import CoreData
import MediaPlayer

class SongApple: Song {
    @NSManaged var persistentId: NSDecimalNumber
    @NSManaged var bpm: Float
    @NSManaged var beatStartMs: Float
    @NSManaged var peakDb: Float
    @NSManaged var seconds: Float
    
    private var _url: URL?
    
    public var url: URL? {
        if _url == nil {
            let pred = MPMediaPropertyPredicate(value: persistentId, forProperty: MPMediaItemPropertyPersistentID)
            let query = MPMediaQuery(filterPredicates: [pred])
            if let items = query.items,
                let first = items.first {
                _url = first.assetURL
            }
        }
        return _url
    }
    
    override var CanPlay: Bool {
        return bpm > 0
    }
    
    public static func getOrCreateFor(mediaItem: MPMediaItem) -> SongApple {
        let persistentId = mediaItem.persistentID
        let songFetch = NSFetchRequest<SongApple>(entityName: "SongApple")
        songFetch.predicate = NSPredicate(format: "persistentId == %@", NSDecimalNumber(value: persistentId))
        var existingSongs = [SongApple]()
        do {
            existingSongs = try AppDelegate.moc.fetch(songFetch)
        } catch {}
        if let es = existingSongs.last {
            return es
        } else {
            var songTitle = ""
            if let title = mediaItem.title {
                songTitle = title
            }
            if let artist = mediaItem.artist {
                songTitle += " | " + artist
            }
            
            return SongApple(persistentId: persistentId, title: songTitle, seconds: Float(mediaItem.playbackDuration))
        }
    }
    
    init(persistentId: UInt64, title: String, seconds: Float) {
        super.init(entity: NSEntityDescription.entity(forEntityName: "SongApple", in: AppDelegate.moc)!, insertInto: AppDelegate.moc)
        self.persistentId = NSDecimalNumber(value: persistentId)
        self.title = title
        self.seconds = seconds
    }
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    public func calcSpecs() {
        if let url = url {
            let analyzer = BPMDetector()
            analyzer.calc(url)
            seconds = analyzer.getDurationSeconds()
            bpm = analyzer.getBpm()
            beatStartMs = analyzer.getBeatStartMs()
            peakDb = analyzer.getPeakDb()
        }
        if bpm == 0 {
            print("Error on song \(title)!")
        }
    }
    
    public func playIn(advPlayer: AdvPlayer) {
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
        if let url = url {
            advPlayer.play(url)
            advPlayer.setOrigBpm(bpm, beatStartMs: beatStartMs)
            advPlayer.setVolume(powf(2, peakDb / -3)) // Normalization!
        }
    }
    
    public func doesExist() -> Bool {
        return url != nil
    }
}
