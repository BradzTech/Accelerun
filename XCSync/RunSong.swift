//
//  RunSong.swift
//  XCSync
//
//  Created by Bradley Klemick on 6/10/17.
//  Copyright © 2017 BradzTech. All rights reserved.
//

import CoreData
import MediaPlayer

class RunSong: NSManagedObject {
    @NSManaged var url: String
    @NSManaged var name: String
    @NSManaged var bpm: Float
    @NSManaged var beatStartMs: Float
    @NSManaged var peakDb: Float
    @NSManaged var motivationRating: Int16
    
    var Url: URL {
        return URL(string: url)!
    }
    
    init(assetUrl: URL) {
        super.init(entity: NSEntityDescription.entity(forEntityName: "RunSong", in: AppDelegate.moc)!, insertInto: AppDelegate.moc)
        url = assetUrl.absoluteString
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
            print("Error on song \(name)!")
        }
    }
    
    func playIn(advPlayer: AdvPlayer) {
        advPlayer.play(Url)
        advPlayer.setVolume(powf(2, peakDb / -10)) // Normalization!
        advPlayer.setTempo(1)
        advPlayer.setBpm(bpm, beatStartMs: beatStartMs)
    }
}
