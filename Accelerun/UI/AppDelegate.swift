//
//  AppDelegate.swift
//  Accelerun
//
//  Created by Bradley Klemick on 6/9/17.
//  Copyright © 2017 BradzTech. All rights reserved.
//

import UIKit
import CoreData
import MediaPlayer

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    private var wasPlaying = false
    private static var _appIsOpen = true
    
    public var window: UIWindow?
    public static var appIsOpen: Bool {
        return _appIsOpen
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Initialize API Keys
        if let path = Bundle.main.path(forResource: "Keys", ofType: "plist") {
            let keys = NSDictionary(contentsOfFile: path)
            if let superpoweredKey = keys?["Superpowered"] as? String {
                BPMDetector().initSuperpowered(superpoweredKey)
            }
            if let youtubeKey = keys?["YouTube"] as? String {
                AppDelegate._youtubeKey = youtubeKey
            }
        }
        return true
    }
    
    private static var _youtubeKey: String?
    public static var youtubeKey: String {
        return _youtubeKey!
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        if ViewController.inst.playing {
            if let _ = ViewController.inst.cSong as? SongYoutube {
                ViewController.inst.playing = false
                wasPlaying = true
            }
        } else {
            // If first song is paused, then second app is closed, remove now playing
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        }
        AppDelegate._appIsOpen = false
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        if wasPlaying {
            wasPlaying = false
            ViewController.inst.playing = true
        }
        AppDelegate._appIsOpen = true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        AppDelegate.saveContext()
    }

    // MARK: - Core Data stack
    
    static var moc: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    static var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "Accelerun")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                if let documentsUrl = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                    let corruptUrl = documentsUrl.appendingPathComponent("Accelerun.sqlite")
                    try? FileManager.default.removeItem(at: corruptUrl)
                }
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    static func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}

public enum DefaultsKey: String {
    case lastTempo = "lastTempo"
    case ytDisclaimer = "ytDisclaimer"
}
