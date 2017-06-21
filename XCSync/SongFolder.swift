//
//  RunPlaylist.swift
//  XCSync
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
    
    func songAt(index: Int) -> Song? {
        // TODO: skip subfolders (and numSongs)
        return at(index: index) as? Song
    }
    
    func numSongs() -> Int {
        return items.count
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
