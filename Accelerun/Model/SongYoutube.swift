//
//  SongYoutube.swift
//  Accelerun
//
//  Created by Bradley Klemick on 5/20/19.
//  Copyright © 2019 BradzTech. All rights reserved.
//

import CoreData
import WebKit

class SongYoutube: Song {
    @NSManaged var videoId: String
    @NSManaged var bpm: Float
    @NSManaged var beatFingerprint: [Float]
    @NSManaged var seconds: Float
    
    var Url: URL {
        return URL(string: "https://www.youtube.com/watch?v=" + videoId)!
    }
    
    override var CanPlay: Bool {
        return bpm > 0
    }
    
    init(videoId: String, title: String) {
        super.init(entity: NSEntityDescription.entity(forEntityName: "SongYoutube", in: AppDelegate.moc)!, insertInto: AppDelegate.moc)
        self.videoId = videoId
        self.title = title
    }
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    func playIn(webView: WKWebView) {
        if bpm == 0 {
            BackgroundAnalyzer.rescan(ytCallback: {() in
                self.finishPlay(webView: webView)
            })
        } else {
            finishPlay(webView: webView)
        }
    }
    
    public func finishPlay(webView: WKWebView) {
        webView.isHidden = false
        webView.evaluateJavaScript("playVideo('\(videoId)');", completionHandler: {(res, error) in
            ViewController.inst.upTempo()
        })
    }
}
