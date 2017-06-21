//
//  SongTableVC.swift
//  XCSync
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
    var otherToolbarItems: [UIBarButtonItem] = []
    
    override func viewDidLoad() {
        self.navigationItem.setLeftBarButton(nil, animated: true)
        otherToolbarItems = [UIBarButtonItem(title: "Add Song(s)", style: .plain, target: self, action: #selector(addBtn(_:))), UIBarButtonItem(title: "New Playlist", style: .plain, target: self, action: #selector(addPlaylist(_:)))]
        if folder == nil {
            otherToolbarItems.remove(at: 0)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setToolbarHidden(false, animated: true)
        let songFetch = NSFetchRequest<SongItem>(entityName: "SongItem")
        if let folder = folder {
            songFetch.predicate = NSPredicate(format: "ANY folders == %@", folder)
        } else {
            songFetch.predicate = NSPredicate(format: "folders.@count == 0")
        }
        do {
            songItems = try AppDelegate.moc.fetch(songFetch)
        } catch {}
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setToolbarHidden(true, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let songItem = songItems[indexPath.row]
        if songItem is SongFolder {
            let cell = tableView.dequeueReusableCell(withIdentifier: "folderCell")!
            cell.textLabel?.text = songItems[indexPath.row].title
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "songCell")!
            cell.textLabel?.text = songItems[indexPath.row].title
            return cell
            
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let songItem = songItems[indexPath.row]
        if let folder = songItem as? SongFolder {
            tableView.deselectRow(at: indexPath, animated: true)
            let songTableVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SongTableVC") as! SongTableVC
            songTableVC.folder = folder
            navigationController!.pushViewController(songTableVC, animated: true)
        } else {
            goToNowPlaying()
            ViewController.inst.play(folder: folder!, index: indexPath.row)
        }
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
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
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        // TODO: root view?
        folder!.itemsSet.moveObjects(at: IndexSet.init(integer: sourceIndexPath.row), to: destinationIndexPath.row)
        if let vc = ViewController.inst,
            let csong = vc.cSong {
            if vc.cFolder == folder {
                vc.cIndex = folder!.itemsSet.index(of: csong)
            }
        }
        AppDelegate.saveContext()
    }
    
    @IBAction func editBtn(_ sender: Any) {
        let editing = !self.isEditing
        self.setEditing(editing, animated: true)
        let newButton = UIBarButtonItem(barButtonSystemItem: editing ? .done : .edit, target: self, action: #selector(editBtn(_:)))
        self.navigationItem.setRightBarButton(newButton, animated: true)
        self.toolbarItems = otherToolbarItems
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
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
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
    
    @IBAction func goToNowPlaying(_ sender: Any? = nil) {
        var rootVC: ViewController?
        if let rvc = ViewController.inst {
            rootVC = rvc
        } else {
            rootVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "NowPlaying") as? ViewController
        }
        rootVC!.modalTransitionStyle = .flipHorizontal
        present(rootVC!, animated: true, completion: nil)
    }
}
