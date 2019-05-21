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
    
    public func doesExist() -> Bool {
        if let _ = try? AVAudioPlayer(contentsOf: Url) {
            return true
        }
        return false
    }
}

class BackgroundAnalyzer {
    static var active: Bool = false
    
    static func rescan(ytCallback: (() -> Void)? = nil) {
        let ytFetch = NSFetchRequest<SongYoutube>(entityName: "SongYoutube")
        ytFetch.predicate = NSPredicate(format: "seconds == 0")
        if let yts = try? AppDelegate.moc.fetch(ytFetch) {
            if yts.count > 0 {
                var requestArr = [String]()
                for yt in yts {
                    requestArr.append(yt.videoId)
                }
                if let requestJson = try? JSONSerialization.data(withJSONObject: ["videoIds": requestArr], options: .init()) {
                    var request = URLRequest(url: URL(string: "https://bradztech.com/c/ios/accelerun/calcyt.php")!)
                    request.httpMethod = "POST"
                    request.httpBody = requestJson
                    URLSession.shared.dataTask(with: request, completionHandler: {(data, response, error) in
                        if let data = data {
                            if let jsonRoot = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [[String: Any]] {
                                for i in 0..<jsonRoot.count {
                                    let jsonItem = jsonRoot[i]
                                    if let seconds = jsonItem["seconds"] as? Double,
                                        let bpm = jsonItem["bpm"] as? Double {
                                        let yt = yts[i]
                                        yt.seconds = Float(seconds)
                                        yt.bpm = Float(bpm)
                                        var bfFloats = [Float]()
                                        if let beatFingerprint = jsonItem["beatFingerprint"] as? [Double] {
                                            for bf in beatFingerprint {
                                                bfFloats.append(Float(bf))
                                            }
                                        }
                                        yt.beatFingerprint = bfFloats
                                    }
                                }
                                AppDelegate.saveContext()
                            }
                        }
                        ytCallback?()
                    }).resume()
                }
            }
        }
        
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
