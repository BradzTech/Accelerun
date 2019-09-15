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
    var songItems = [Song]()
    var folder: SongFolder?
    private var toolGroups = [[UIBarButtonItem]]()
    private var playlistLengthStr: String {
        var numSongs = 0
        var totalSeconds: Float = 0.0
        for songItem in songItems {
            if let song = songItem as? SongApple {
                numSongs += 1
                totalSeconds += song.seconds
            } else if let song = songItem as? SongYoutube {
                numSongs += 1
                totalSeconds += song.seconds
            }
        }
        return "\(numSongs) tracks, ~\(Int(floor(totalSeconds / 60))) minutes"
    }
    
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
        let addSong = UIBarButtonItem(title: "Add from Library", style: .plain, target: self, action: #selector(addBtn(_:)))
        let newPlaylist = UIBarButtonItem(title: "New Playlist", style: .plain, target: self, action: #selector(addPlaylist(_:)))
        let addYt = UIBarButtonItem(title: "Search YouTube", style: .plain, target: self, action: #selector(addYoutube(_:)))
        let nowPlaying = UIBarButtonItem(title: "Return to Player", style: .plain, target: self, action: #selector(goToNowPlaying(_:)))
        toolGroups = [[flexSpace, nowPlaying, flexSpace], [addSong, flexSpace, addYt]]
        self.navigationController!.toolbar.barStyle = .blackTranslucent
        if folder == nil {
            folder = SongFolder.rootFolder
            toolGroups[1].remove(at: 0)
            toolGroups[1][1] = newPlaylist
            navigationItem.title = "Playlists"
        }
        
        if folder == SongFolder.rootFolder {
            if let cFolder = ViewController.inst.cFolder {
                open(folder: cFolder, animated: false)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let itemsSet = folder!.itemsSet
        var si = [Song]()
        for item in itemsSet {
            if let songItem = item as? Song {
                si.append(songItem)
            }
        }
        songItems = si
        
        editingMode = songItems.count == 0
        for tg in toolGroups {
            for tb in tg {
                tb.tintColor = view.tintColor
            }
        }
        upSelected()
    }
    
    private func upSelected() {
        if let beforeRow = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: beforeRow, animated: true)
        }
        for i in 0..<songItems.count {
            if songItems[i] == ViewController.inst?.cSong {
                tableView.selectRow(at: IndexPath(row: i, section: 0), animated: true, scrollPosition: .middle)
            }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? songItems.count: 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
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
                cell.textLabel?.text = playlistLengthStr
                return cell
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            let songItem = songItems[indexPath.row]
            if let folder = songItem as? SongFolder {
                tableView.deselectRow(at: indexPath, animated: true)
                open(folder: folder, animated: true)
            } else if let song = songItem as? SongApple {
                if song.bpm > 0 {
                    if song.doesExist() {
                        self.playIndex(indexPath)
                    } else {
                        alertNotExist(index: indexPath.row)
                    }
                } else {
                    alertAnalysis()
                }
            } else if let song = songItem as? SongYoutube {
                if song.seconds < 0 {
                    BackgroundAnalyzer.rescan(ytCallback: {() in
                        DispatchQueue.main.async {
                            if song.seconds == 0 {
                                self.alertAnalysis()
                            } else {
                                self.playIndex(indexPath)
                            }
                        }
                    })
                } else {
                    if song.bpm == 0 {
                        self.alertTooLong(index: indexPath.row)
                    } else {
                        self.playIndex(indexPath)
                    }
                }
            }
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    private func alertAnalysis() {
        let alert = UIAlertController(title: "Song Analysis in Progress", message: "Please try again in several seconds.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    private func alertNotExist(index: Int) {
        let alert = UIAlertController(title: "Could not find file!", message: "Sorry about that. Please re-add it from your library.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
        remove(index: index)
    }
    
    private func alertTooLong(index: Int) {
        let alert = UIAlertController(title: "Song Too Long", message: "Sorry, this song is either too long, or no beat was detected. Please use a shorter song with a constant rhythm.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
        remove(index: index)
    }
    
    private func playIndex(_ indexPath: IndexPath) {
        ViewController.inst.play(folder: folder!, index: indexPath.row)
        goToNowPlaying()
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        if indexPath.section == 0 {
            let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete", handler: {(rowAction, indexPath) in
                self.remove(index: indexPath.row)
            })
            return [deleteAction]
        }
        return []
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 0
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 0
    }
    
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        var needsExchange = true
        if let vc = ViewController.inst,
            let csong = vc.cSong {
            if vc.cFolder == folder {
                folder!.itemsSet.exchangeObject(at: sourceIndexPath.row, withObjectAt: destinationIndexPath.row)
                vc.cIndex = folder!.itemsSet.index(of: csong)
                needsExchange = false
            }
        }
        if needsExchange {
            folder!.itemsSet.exchangeObject(at: sourceIndexPath.row, withObjectAt: destinationIndexPath.row)
        }
        AppDelegate.saveContext()
        upSelected()
    }
    
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if proposedDestinationIndexPath.section > 0 {
            return IndexPath(row: songItems.count - 1, section: 0)
        }
        return proposedDestinationIndexPath
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 || folder != SongFolder.rootFolder {
            return 54
        } else {
            return 260
        }
    }
    
    @IBAction func editBtn(_ sender: Any? = nil) {
        editingMode = !editingMode
    }
    
    @objc func addBtn(_ sender: Any) {
        let pickerController = MPMediaPickerController(mediaTypes: .music)
        pickerController.allowsPickingMultipleItems = false
        pickerController.prompt = "Tap a track to add it to the playlist."
        pickerController.delegate = self
        present(pickerController, animated: true, completion: nil)
    }
    
    @objc func addPlaylist(_ sender: Any) {
        let alertController = UIAlertController(title: "Folder Name:", message: nil, preferredStyle: .alert)
        alertController.addTextField(configurationHandler: {(textField) in
            textField.autocapitalizationType = .words
        })
        alertController.addAction(UIAlertAction(title: "Create", style: .default, handler: {(action) in
            let songFolder = SongFolder(Title: alertController.textFields![0].text!, Folder: self.folder)
            self.add(songItem: songFolder)
            self.open(folder: songFolder, animated: true)
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    @objc func addYoutube(_ sender: Any) {
        let youtubeVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "YoutubeSelectVC") as! YoutubeSelectVC
        youtubeVC.pvc = self
        navigationController!.pushViewController(youtubeVC, animated: true)
    }
    
    private func open(folder: SongFolder, animated: Bool) {
        let songTableVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SongTableVC") as! SongTableVC
        songTableVC.folder = folder
        navigationController!.pushViewController(songTableVC, animated: animated)
    }
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        mediaPicker.dismiss(animated: true, completion: nil)
    }
    
    /**
     * Get cached song if it exists, otherwise create one. Then add it to the current folder.
     */
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        mediaPicker.dismiss(animated: true, completion: nil)
        // Sleep a bit so we don't get a table out of view hierarchy warning
        DispatchQueue.global(qos: .userInitiated).async(execute: {
            usleep(100000)
            // Add each item to playlist, both database-side and visually
            for mediaItem in mediaItemCollection.items {
                let song = SongApple.getOrCreateFor(mediaItem: mediaItem)
                song.foldersSet.add(self.folder!)
                self.add(songItem: song)
            }
            BackgroundAnalyzer.rescan()
        })
    }
    
    public func add(songItem: Song) {
        songItems.append(songItem)
        AppDelegate.saveContext()
        tableView.insertRows(at: [IndexPath(row: self.songItems.count - 1, section: 0)], with: .top)
        tableView.reloadSections(IndexSet(integer: 1), with: .fade)
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
        tableView.reloadSections(IndexSet(integer: 1), with: .fade)
        if let VC = ViewController.inst {
            if VC.cFolder == folder && VC.cIndex == index {
                ViewController.inst?.btnNext()
                ViewController.inst?.btnPrev()
            }
        }
    }
    
    @objc func goToNowPlaying(_ sender: Any? = nil) {
        DispatchQueue.main.async {
            if ViewController.inst.cSong == nil {
                let alert = UIAlertController(title: "No Music", message: "Please select a song to begin playback.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
}
