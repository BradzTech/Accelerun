//
//  SongTableVC.swift
//  Accelerun
//
//  Created by Bradley Klemick on 6/11/17.
//  Copyright © 2017 BradzTech. All rights reserved.
//

import UIKit
import CoreData
import MediaPlayer

class SongTableVC: UITableViewController, MPMediaPickerControllerDelegate {
    var songItems = [SongItem]()
    var folder: SongFolder?
    private var toolGroups = [[UIBarButtonItem]]()
    
    var editingMode: Bool {
        get {
            return self.isEditing
        } set {
            let editing = newValue
            self.setEditing(editing, animated: true)
            let newButton = UIBarButtonItem(barButtonSystemItem: editing ? .done : .edit, target: self, action: #selector(editBtn(_:)))
            self.navigationItem.setRightBarButton(newButton, animated: true)
            self.setToolbarItems(toolGroups[editing ? 1 : 0], animated: true)
        }
    }
    
    override func viewDidLoad() {
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let addSong = UIBarButtonItem(title: "Add Song(s)", style: .plain, target: self, action: #selector(addBtn(_:)))
        let newPlaylist = UIBarButtonItem(title: "New Playlist", style: .plain, target: self, action: #selector(addPlaylist(_:)))
        let nowPlaying = UIBarButtonItem(title: "Return to Player", style: .plain, target: self, action: #selector(goToNowPlaying(_:)))
        toolGroups = [[flexSpace, nowPlaying, flexSpace], [addSong, flexSpace, newPlaylist]]
        self.navigationController!.toolbar.barStyle = .blackTranslucent
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setToolbarHidden(false, animated: true)
        if folder == nil {
            folder = SongFolder.rootFolder
        }
        let itemsSet = folder!.itemsSet
        var si = [SongItem]()
        for item in itemsSet {
            if let songItem = item as? SongItem {
                si.append(songItem)
            }
        }
        songItems = si
        
        editingMode = songItems.count == 0
        for tg in toolGroups {
            for tb in tg {
                tb.tintColor = navigationItem.rightBarButtonItem?.tintColor
            }
        }
        for i in 0..<songItems.count {
            if songItems[i] == ViewController.inst?.cSong {
                tableView.selectRow(at: IndexPath(row: i, section: 0), animated: true, scrollPosition: .middle)
            }
        }
        if folder == SongFolder.rootFolder {
            // TODO: remove Add Song button
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setToolbarHidden(true, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songItems.count + 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row < songItems.count {
            let songItem = songItems[indexPath.row]
            if songItem is SongFolder {
                let cell = tableView.dequeueReusableCell(withIdentifier: "folderCell")!
                cell.textLabel?.text = songItems[indexPath.row].title
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "songCell")!
                let bgView = UIView()
                bgView.backgroundColor = UIColor(white: 1.0, alpha: 0.3)
                cell.selectedBackgroundView = bgView
                cell.textLabel?.text = songItems[indexPath.row].title
                return cell
            }
        } else {
            if folder == SongFolder.rootFolder {
                let cell = tableView.dequeueReusableCell(withIdentifier: "appDesc")!
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "playlistTotal")!
                cell.textLabel?.text = "Total length: ??:??"
                return cell
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row < songItems.count {
            let songItem = songItems[indexPath.row]
            if let folder = songItem as? SongFolder {
                tableView.deselectRow(at: indexPath, animated: true)
                open(folder: folder)
            } else {
                goToNowPlaying(true)
                ViewController.inst.play(folder: folder!, index: indexPath.row)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        if indexPath.row < songItems.count {
            /*let moveAction = UITableViewRowAction(style: .default, title: "Fix Beat", handler: {(rowAction, indexPath) in
             if let newVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MusicAddVC") as? MusicAddVC {
             newVC.songItem = self.songItems[indexPath.row]
             self.navigationController!.pushViewController(newVC, animated: true)
             }
             })*/
            let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete", handler: {(rowAction, indexPath) in
                self.remove(index: indexPath.row)
            })
            return [deleteAction]
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return indexPath.row < songItems.count
    }
    
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        folder!.itemsSet.exchangeObject(at: sourceIndexPath.row, withObjectAt: destinationIndexPath.row)
        if let vc = ViewController.inst,
            let csong = vc.cSong {
            if vc.cFolder == folder {
                vc.cIndex = folder!.itemsSet.index(of: csong)
            }
        }
        AppDelegate.saveContext()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row < songItems.count || folder != SongFolder.rootFolder {
            return 54
        } else {
            return 150
        }
    }
    
    @IBAction func editBtn(_ sender: Any? = nil) {
        editingMode = !editingMode
    }
    
    func addBtn(_ sender: Any) {
        let pickerController = MPMediaPickerController(mediaTypes: .music)
        pickerController.allowsPickingMultipleItems = true
        pickerController.delegate = self
        present(pickerController, animated: true, completion: nil)
    }
    
    func addPlaylist(_ sender: Any) {
        let alertController = UIAlertController(title: "Folder Name:", message: nil, preferredStyle: .alert)
        alertController.addTextField(configurationHandler: {(textField) in
        })
        alertController.addAction(UIAlertAction(title: "Create", style: .default, handler: {(action) in
            let songFolder = SongFolder(Title: alertController.textFields![0].text!, Folder: self.folder)
            self.add(songItem: songFolder)
            self.open(folder: songFolder)
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    private func open(folder: SongFolder) {
        let songTableVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SongTableVC") as! SongTableVC
        songTableVC.folder = folder
        navigationController!.pushViewController(songTableVC, animated: true)
    }
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        mediaPicker.dismiss(animated: true, completion: nil)
    }
    
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        mediaPicker.dismiss(animated: true, completion: nil)
        for mediaItem in mediaItemCollection.items {
            if let assetUrl = mediaItem.assetURL {
                let songFetch = NSFetchRequest<Song>(entityName: "Song")
                songFetch.predicate = NSPredicate(format: "url == %@", assetUrl.absoluteString)
                var existingSongs = [Song]()
                do {
                    existingSongs = try AppDelegate.moc.fetch(songFetch)
                } catch {}
                var song: Song?
                if let es = existingSongs.last {
                    song = es
                } else {
                    var songTitle = ""
                    if let title = mediaItem.title {
                        songTitle = title
                    }
                    if let artist = mediaItem.artist {
                        songTitle += " | " + artist
                    }
                    song = Song(assetUrl: assetUrl, title: songTitle, seconds: Float(mediaItem.playbackDuration))
                }
                song!.foldersSet.add(folder!)
                add(songItem: song!)
            }
        }
        BackgroundAnalyzer.rescan()
    }
    
    private func add(songItem: SongItem) {
        songItems.append(songItem)
        AppDelegate.saveContext()
        tableView.insertRows(at: [IndexPath(row: self.songItems.count - 1, section: 0)], with: .top)
    }
    
    private func remove(index: Int) {
        let songItem = songItems[index]
        folder!.itemsSet.remove(songItem)
        if songItem is SongFolder {
            songItem.delete()
        }
        AppDelegate.saveContext()
        songItems.remove(at: index)
        tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .top)
    }
    
    func goToNowPlaying(_ sender: Bool = false) {
        var rootVC: ViewController?
        if let rvc = ViewController.inst {
            rootVC = rvc
        } else if sender {
            rootVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "NowPlaying") as? ViewController
        } else {
            let alert = UIAlertController(title: "No Music", message: "Please select a song to begin playback.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }
        if let rvc = rootVC {
            rvc.modalTransitionStyle = .flipHorizontal
            present(rvc, animated: true, completion: nil)
        }
    }
}
