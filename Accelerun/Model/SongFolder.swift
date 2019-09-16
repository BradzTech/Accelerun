//
//  RunPlaylist.swift
//  Accelerun
//
//  Created by Bradley Klemick on 6/20/17.
//  Copyright © 2017 BradzTech. All rights reserved.
//

import CoreData

class SongFolder: Song {
    @NSManaged var items: Set<Song>
    
    var itemsSet: NSMutableOrderedSet {
        return mutableOrderedSetValue(forKey: "items")
    }
    
    init(Title: String, Folder: SongFolder?) {
        super.init(entity: NSEntityDescription.entity(forEntityName: "SongFolder", in: AppDelegate.moc)!, insertInto: AppDelegate.moc)
        title = Title
        Folder?.itemsSet.add(self)
    }
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    func at(index: Int) -> Song? {
        if index >= 0 && index < items.count {
            return songs[index]
        }
        return nil
    }
    
    // Note: inefficient with large playlists
    private var songs: [Song] {
        return Array(items)
    }
    func songAt(index: Int) -> Song? {
        return songs[index]
    }
    
    func numSongs() -> Int {
        return songs.count
    }
    
    // Fetch root folder, create if it does not yet exist.
    static var rootFolder: SongFolder {
        let folderFetch = NSFetchRequest<SongFolder>(entityName: "SongFolder")
        folderFetch.predicate = NSPredicate(format: "folders.@count == 0")
        var theFolder: SongFolder?
        do {
            let fetchRes = try AppDelegate.moc.fetch(folderFetch)
            theFolder = fetchRes.first
        } catch {}
        if theFolder == nil {
            theFolder = SongFolder(Title: "", Folder: nil)
            AppDelegate.saveContext()
        }
        return theFolder!
    }
}
