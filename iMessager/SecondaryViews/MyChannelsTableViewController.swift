//
//  MyChannelsTableViewController.swift
//  iMessager
//
//  Created by 高橋悟生 on 2023/01/31.
//

import UIKit

class MyChannelsTableViewController: UITableViewController {
    
    // MARK: - Vars
    var myChannels: [Channel] = []
    
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        
        downloadUserChannels()
        
    }
    
    // MARK: - Download Channels
    private func downloadUserChannels() {
        
        FirebaseChannelListener.shared.downloadUserChannelsFromFirebase { (allChannels) in
            
            self.myChannels = allChannels
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            
        }
        
    }
    
    
    // MARK: - IBActions
    @IBAction func addBarButtonPresed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "myChannelToAddSeg", sender: self)
    }
    

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myChannels.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ChannelTableViewCell
        
        cell.configure(channel: myChannels[indexPath.row])

        return cell
    }
    
    
    // MARK: - Table view Delegates
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        // channel viewに移動
        performSegue(withIdentifier: "myChannelToAddSeg", sender: myChannels[indexPath.row])
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {

        let deleteButton: UITableViewRowAction = UITableViewRowAction(style: .normal, title: "削除") { (action, index) -> Void in
            let channelToDelete = self.myChannels[indexPath.row]
            self.myChannels.remove(at: indexPath.row)
            
            FirebaseChannelListener.shared.deleteChannel(channelToDelete)
            
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        deleteButton.backgroundColor = UIColor.red

        return [deleteButton]
    }
    
//    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
//
//        if editingStyle == .delete {
//
//            let channelToDelete = myChannels[indexPath.row]
//            myChannels.remove(at: indexPath.row)
//
//            FirebaseChannelListener.shared.deleteChannel(channelToDelete)
//
//            tableView.deleteRows(at: [indexPath], with: .automatic)
//
//        }
//
//    }
    
    
    // MARK: - Edit Segue Prepare
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "myChannelToAddSeg" {
            
            let editChannelView = segue.destination as! AddChannelTableViewController
            editChannelView.channelToEdit = sender as? Channel
            
        }
        
    }
    
    
    // MARK: - delete Helper
    func deleteMyChannels() {
        
        if FirebaseChannelListener.shared.channelListener == nil {
            downloadUserChannels()
        }
        
        var deleteChannels = myChannels
        
        for deleteChannel in deleteChannels {
            FirebaseChannelListener.shared.deleteChannel(deleteChannel)
        }
        
    }
    
    
    
}
