//
//  AboutVC.swift
//  Accelerun
//
//  Created by Bradley Klemick on 7/2/17.
//  Copyright © 2017 BradzTech. All rights reserved.
//

import UIKit

class AboutVC: UITableViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "descCell", for: indexPath)
        switch indexPath.row {
        case 0:
            cell.textLabel!.text = "Accelerun " + (Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String)
            cell.accessoryType = .none
        case 2:
            cell.textLabel!.text = "Icons provided by icons8.com"
        case 3:
            cell.textLabel!.text = "Powered by Superpowered Audio"
        case 4:
            cell.textLabel!.text = "YouTube Support Information"
        default:
            cell.textLabel!.text = "Created by BradzTech"
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.row {
        case 1:
            UIApplication.shared.open(URL(string: "https://bradztech.com/")!, options: [:], completionHandler: nil)
        case 2:
            UIApplication.shared.open(URL(string: "https://icons8.com/")!, options: [:], completionHandler: nil)
        case 3:
            UIApplication.shared.open(URL(string: "https://superpowered.com/")!, options: [:], completionHandler: nil)
        case 4:
            AboutVC.ytDisclaimer(vc: self)
        default:
            break
        }
    }
    
    public static func ytDisclaimer(vc: UIViewController, onAccept: (() -> ())? = nil) {
        let alert = UIAlertController(title: "YouTube Disclaimer", message: "Please note videos added from YouTube cannot be downloaded ahead of time, so they will require keeping the app open and an active data connection (roughly 4 MB/minute). Furthermore, added songs will be annoymously sent to a remote server for beat analysis.\n\nIf the above is not okay, you can still use Accelerun with only music on your iPhone.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "I understand", style: .default, handler: {(alert: UIAlertAction) in
            UserDefaults.standard.set(true, forKey: DefaultsKey.ytDisclaimer.rawValue)
            onAccept?()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {(alert: UIAlertAction) in
            UserDefaults.standard.set(false, forKey: DefaultsKey.ytDisclaimer.rawValue)
        }))
        vc.present(alert, animated: true, completion: nil)
    }
}
