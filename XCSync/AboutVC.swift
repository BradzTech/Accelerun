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
        return 4
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
        default:
            cell.textLabel!.text = "Created by BradzTech"
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.row {
        case 1:
            UIApplication.shared.open(URL(string: "https://bradztech.com/")!, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
        case 2:
            UIApplication.shared.open(URL(string: "https://icons8.com/")!, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
        case 3:
            UIApplication.shared.open(URL(string: "https://superpowered.com/")!, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
        default:
            break
        }
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
