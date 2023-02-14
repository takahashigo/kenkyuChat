//
//  ChannelRequestsTableViewController.swift
//  iMessager
//
//  Created by 高橋悟生 on 2023/02/03.
//

import UIKit

class ChannelRequestsTableViewController: UITableViewController {
    
    // MARK: - Vars
    var myChannelRequests: [ChannelRequest] = []
    var delegate: ChannelDetailTableViewControllerDelegate?
    var changeChannel: Channel?
    
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        
        
        downloadRequestChannels()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        removeListener()
        
        
    }
    
    // MARK: - Download channelRequests
    private func downloadRequestChannels() {
        
        FirebaseChannelRequestListener.shared.downloadRequestChannelsFromFirebase { allChannelRequests in
            
            self.myChannelRequests = allChannelRequests
            print(self.myChannelRequests.count)
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            
        }
        
    }
    
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return myChannelRequests.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        // Configure the cell...
        cell.textLabel?.numberOfLines=1
        cell.textLabel?.text = "\(myChannelRequests[indexPath.row].requestUsername)さんから\(myChannelRequests[indexPath.row].channelName)への参加許可依頼"
        cell.textLabel?.font = UIFont(name: "Avenir", size: 14)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
//    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
//        return true
//    }
//
//    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
//
//        if editingStyle == .delete {
//
//            let channelRequestToDelete = myChannelRequests[indexPath.row]
//            myChannelRequests.remove(at: indexPath.row)
//            FirebaseChannelRequestListener.shared.deleteChannel(channelRequestToDelete)
//            tableView.deleteRows(at: [indexPath], with: .automatic)
//
//        }
//
//
//    }
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let editAction = UIContextualAction(style: .normal, title: "承認") { (action, view, completionHandler) in
            
            //処理を記述
            let channelRequestToConsign = self.myChannelRequests[indexPath.row]
            // channelにメンバー追加
            
            FirebaseChannelListener.shared.downloadIdentifyChannel(channelId: channelRequestToConsign.channelId) { channel in
                self.changeChannel = channel
                if var changeChannel = self.changeChannel {
                    changeChannel.memberIds.append(channelRequestToConsign.requestUserId)
                    FirebaseChannelListener.shared.saveChannel(changeChannel)
                    self.delegate?.didClickFollow()
                    
                    // localChannelRequestから削除
                    self.myChannelRequests.remove(at: indexPath.row)
                    
                    
                    // send pushNotification
                    PushNotificationService.shared.sendChannelRequestPushNotificationTo(userId: channelRequestToConsign.requestUserId,title: "参加承認", body: "\(channelRequestToConsign.channelName)への参加が許可されました。", channelRequest: channelRequestToConsign)
                    
                    // remove from firestore
                    FirebaseChannelRequestListener.shared.deleteChannelRequest(channelRequestToConsign)
                    self.tableView.deleteRows(at: [indexPath], with: .automatic)
                }
            }
            

            // 実行結果に関わらず記述
            completionHandler(true)
        }
        
        editAction.backgroundColor = .green
        
        return UISwipeActionsConfiguration(actions: [editAction])
    }
    
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .normal, title: "拒否") { (action, view, completionHandler) in
            
            //処理を記述
            let channelRequestToDelete = self.myChannelRequests[indexPath.row]
            self.myChannelRequests.remove(at: indexPath.row)
            FirebaseChannelRequestListener.shared.deleteChannelRequest(channelRequestToDelete)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            
            // send pushNotification
            PushNotificationService.shared.sendChannelRequestPushNotificationTo(userId: channelRequestToDelete.requestUserId,title: "参加拒否", body: "\(channelRequestToDelete.channelName)への参加が拒否されました。", channelRequest: channelRequestToDelete)
            
            
            
            // 実行結果に関わらず記述
            completionHandler(true)
        }
        
        deleteAction.backgroundColor = .red
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    

    
    private func removeListener() {
        FirebaseChannelRequestListener.shared.removeListeners()
    }
    
    // MARK: - delete helpers
//    func deleteChannelRequests() {
//        if FirebaseChannelRequestListener.shared.channelRequestListener == nil {
//            downloadRequestChannels()
//        }
//
//        var deleteChannelRequests = myChannelRequests
//
//        for deleteChannelRequest in deleteChannelRequests {
//            FirebaseChannelRequestListener.shared.deleteChannelRequest(deleteChannelRequest)
//        }
//    }
    
    
    
}
