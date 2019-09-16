//
//  Song.swift
//  Accelerun
//
//  Created by Bradley Klemick on 9/15/19.
//  Copyright © 2019 BradzTech. All rights reserved.
//

import CoreData

class Song: NSManagedObject {
    @NSManaged var title: String
    @NSManaged var folders: NSSet
    
    var foldersSet: NSMutableSet {
        return mutableSetValue(forKey: "folders")
    }
    
    var CanPlay: Bool {
        return false
    }
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    func delete() {
        do {
            AppDelegate.moc.delete(self)
            try AppDelegate.moc.save()
        } catch _ {}
    }
}

class BackgroundAnalyzer {
    static var active: Bool = false
    
    static func rescan(ytCallback: (() -> Void)? = nil) {
        let ytFetch = NSFetchRequest<SongYoutube>(entityName: "SongYoutube")
        ytFetch.predicate = NSPredicate(format: "seconds < 0")
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
                                    if let seconds = jsonItem["seconds"] as? NSNumber,
                                        let bpm = jsonItem["bpm"] as? NSNumber {
                                        let yt = yts[i]
                                        yt.seconds = seconds.floatValue
                                        yt.bpm = bpm.floatValue
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
            
            let songFetch = NSFetchRequest<SongApple>(entityName: "SongApple")
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
