//
//  SongTableVC.swift
//  XCSync
//
//  Created by Bradley Klemick on 6/11/17.
//  Copyright © 2017 BradzTech. All rights reserved.
//

import UIKit
import CoreData

class SongTableVC: UITableViewController {
    var songs = [RunSong]()
    
    override func viewWillAppear(_ animated: Bool) {
        let fetchReq = NSFetchRequest<RunSong>(entityName: "RunSong")
        do {
            songs = try AppDelegate.moc.fetch(fetchReq)
        } catch {}
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "songCell")!
        cell.textLabel?.text = songs[indexPath.row].name
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        ViewController.inst.play(song: songs[indexPath.row])
    }
    
}
