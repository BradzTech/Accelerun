//
//  YoutubeSelectVC.swift
//  Accelerun
//
//  Created by Bradley Klemick on 5/20/19.
//  Copyright © 2019 BradzTech. All rights reserved.
//

import UIKit
import CoreData

class YoutubeSelectVC: UITableViewController, UITextFieldDelegate {
    var results = [YoutubeResult]()
    public var pvc: SongTableVC!
    
    override func viewDidLoad() {
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count + 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "searchCell", for: indexPath)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ytCell", for: indexPath) as! YTCell
            let result = results[indexPath.row - 1]
            cell.lblTitle.text = result.title + "\n\n" + result.channelTitle
            URLSession.shared.dataTask(with: result.thumbnail, completionHandler: {(data, response, error) in
                if let data = data {
                    let image = UIImage(data: data)
                    DispatchQueue.main.async {
                        cell.imgThumb.image = image
                    }
                }
            }).resume()
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row > 0 {
            let result = results[indexPath.row - 1]
            
            let songFetch = NSFetchRequest<SongYoutube>(entityName: "SongYoutube")
            songFetch.predicate = NSPredicate(format: "videoId == %@", result.videoId)
            var existingSongs = [SongYoutube]()
            do {
                existingSongs = try AppDelegate.moc.fetch(songFetch)
            } catch {}
            var song: SongYoutube?
            if let es = existingSongs.last {
                song = es
            } else {
                song = SongYoutube(videoId: result.videoId, title: result.title)
            }
            navigationController?.popViewController(animated: true)
            song!.foldersSet.add(pvc.folder!)
            pvc.add(songItem: song!)
            AppDelegate.saveContext()
            BackgroundAnalyzer.rescan()
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 100
        } else {
            return 150
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let query = textField.text!.addingPercentEncoding(withAllowedCharacters: CharacterSet())!
        var req = URLRequest(url: URL(string: "https://www.googleapis.com/youtube/v3/search?key=AIzaSyBoHK3SebwUpQYezmM_zvy0w3mKAUG-69o&part=snippet&type=video&q=" + query)!)
        req.addValue(Bundle.main.bundleIdentifier!.trimmingCharacters(in: .whitespacesAndNewlines), forHTTPHeaderField: "X-Ios-Bundle-Identifier")
        URLSession.shared.dataTask(with: req, completionHandler: {(data, response, error) in
            var success = false
            if let data = data {
                if let jsonRoot = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] {
                    if let jsonItems = jsonRoot["items"] as? [[String: Any]] {
                        success = true
                        self.results = [YoutubeResult]()
                        for jsonItem in jsonItems {
                            if let snippet = jsonItem["snippet"] as? [String: Any],
                                let encodedTitle = snippet["title"] as? String,
                                let channelTitle = snippet["channelTitle"] as? String,
                                let jsonId = jsonItem["id"] as? [String: Any],
                                let videoId = jsonId["videoId"] as? String,
                                let thumbJson = snippet["thumbnails"] as? [String: Any],
                                let thumbMed = thumbJson["high"] as? [String: Any],
                                let thumbUrl = thumbMed["url"] as? String,
                                let title = String(htmlEncodedString: encodedTitle) {
                                self.results.append(YoutubeResult(title: title, videoId: videoId, channelTitle: channelTitle, thumbnail: URL(string: thumbUrl)!))
                            }
                        }
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    }
                }
            }
            if !success {
                print(error as Any)
            }
        }).resume()
        textField.resignFirstResponder()
        return true
    }
}

struct YoutubeResult {
    var title: String
    var videoId: String
    var channelTitle: String
    var thumbnail: URL
}

class YTCell: UITableViewCell {
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var imgThumb: UIImageView!
}
