//
//  RunPlaylist.swift
//  Accelerun
//
//  Created by Bradley Klemick on 6/20/17.
//  Copyright © 2017 BradzTech. All rights reserved.
//

import CoreData

class SongFolder: SongItem {
    @NSManaged var items: NSSet
    
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
    
    func at(index: Int) -> SongItem? {
        if index >= 0 && index < items.count {
            return items.allObjects[index] as? SongItem
        }
        return nil
    }
    
    // Note: inefficient with large playlists
    private var songs: [Song] {
        var foundSongs = [Song]()
        for songItem in items {
            if let song = songItem as? Song {
                foundSongs.append(song)
            }
        }
        return foundSongs
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

class SongItem: NSManagedObject {
    @NSManaged var title: String
    @NSManaged var folders: NSSet
    
    var foldersSet: NSMutableSet {
        return mutableSetValue(forKey: "folders")
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
