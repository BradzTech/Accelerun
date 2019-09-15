//
//  YTWebView.swift
//  Accelerun
//
//  Created by Bradley Klemick on 5/21/19.
//  Copyright © 2019 BradzTech. All rights reserved.
//

import WebKit

class YTWebView: WKWebView {
    
    public func getCurrentTime() -> Double {
        let group = DispatchGroup()
        group.enter()
        var ret: Double = 0
        DispatchQueue.main.async {
            self.evaluateJavaScript("player.getCurrentTime();", completionHandler: {(res, error) in
                if let res = res as? Double {
                    ret = res
                }
                group.leave()
            })
        }
        group.wait()
        return ret
    }
    
    public func setCurrentTime(seconds: Double) {
        /*let group = DispatchGroup()
        group.enter()
        DispatchQueue.main.async {
            self.evaluateJavaScript("player.getCurrentTime();", completionHandler: {(res, error) in
                group.leave()
            })
        }
        group.wait()*/
    }
    
    public func resume() {
        self.evaluateJavaScript("player.playVideo();", completionHandler: {(res, error) in
            //group.leave()
        })
        isUserInteractionEnabled = false
    }
    
    public func pause() {
        self.evaluateJavaScript("player.pauseVideo();", completionHandler: {(res, error) in
            //group.leave()
        })
        isUserInteractionEnabled = true
        /*let group = DispatchGroup()
        group.enter()
        DispatchQueue.main.async {
        }
        group.wait()*/
    }
}

extension String {
    
    init?(htmlEncodedString: String) {
        guard let data = htmlEncodedString.data(using: .utf8) else {
            return nil
        }
        
        guard let attributedString = try? NSAttributedString(data: data, options: [
            NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html,
            NSAttributedString.DocumentReadingOptionKey.characterEncoding: String.Encoding.utf8.rawValue
            ], documentAttributes: nil) else {
            return nil
        }
        
        self.init(attributedString.string)
    }
    
}
