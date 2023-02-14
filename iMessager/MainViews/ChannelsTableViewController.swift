//
//  ChannelsTableViewController.swift
//  iMessager
//
//  Created by 高橋悟生 on 2023/01/31.
//

import UIKit

class ChannelsTableViewController: UITableViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var channelSegmentOutlet: UISegmentedControl!
    
    // MARK: - Vars
    var allChannels: [Channel] = []
    var subscribedChannels: [Channel] = []
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        
        navigationItem.largeTitleDisplayMode = .always
        self.title = "トピック"
        
        self.refreshControl = UIRefreshControl()
        self.tableView.refreshControl = self.refreshControl
        
        tableView.tableFooterView = UIView()
        
        downloadAllChannels()
        downloadSubscribedChannels()
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return channelSegmentOutlet.selectedSegmentIndex == 0 ? subscribedChannels.count : allChannels.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ChannelTableViewCell
        let channel = channelSegmentOutlet.selectedSegmentIndex == 0 ? subscribedChannels[indexPath.row] : allChannels[indexPath.row]
        cell.configure(channel: channel)
        
        return cell
    }
    
    
    // MARK: - TableView Delegates
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        if channelSegmentOutlet.selectedSegmentIndex == 1 {
            // チャンネルに移動
            showChannelView(channel: allChannels[indexPath.row])
        } else {
            // チャットに移動
            showChat(channel: subscribedChannels[indexPath.row])
        }
        
    }
    
    
    // edit table cell
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        if channelSegmentOutlet.selectedSegmentIndex == 1 {
            return false
        } else {
            return subscribedChannels[indexPath.row].adminId != User.currentId
        }

    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {

        let deleteButton: UITableViewRowAction = UITableViewRowAction(style: .normal, title: "退会") { (action, index) -> Void in
            var channelToUnfollow = self.subscribedChannels[indexPath.row]
            self.subscribedChannels.remove(at: indexPath.row)
            
            if let index = channelToUnfollow.memberIds.firstIndex(of: User.currentId!) {
                channelToUnfollow.memberIds.remove(at: index)
            }
            
            
            FirebaseChannelListener.shared.saveChannel(channelToUnfollow)
            
            // リロード
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
            
            // 全てのチャンネルをリフレッシュ
            self.downloadAllChannels()
        }
        deleteButton.backgroundColor = UIColor.red

        return [deleteButton]
    }
    
//    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
//
//        if editingStyle == .delete {
//
//            var channelToUnfollow = subscribedChannels[indexPath.row]
//            subscribedChannels.remove(at: indexPath.row)
//
//            if let index = channelToUnfollow.memberIds.firstIndex(of: User.currentId!) {
//                channelToUnfollow.memberIds.remove(at: index)
//            }
//
//            print(channelToUnfollow
//            )
//
//            FirebaseChannelListener.shared.saveChannel(channelToUnfollow)
//
//            // reload(only delete)
//            tableView.deleteRows(at: [indexPath], with: .automatic)
//
//            // refresh allChannels(refresh another allChannels in another tab)
//            self.downloadAllChannels()
//
//        }
//
//    }
    
    
    // MARK: - IBActions
    @IBAction func channelSegmentValueChanged(_ sender: UISegmentedControl) {
        tableView.reloadData()
    }
    
    
    // MARK: - Download channels
    private func downloadAllChannels() {
        
        FirebaseChannelListener.shared.downloadAllChannels { (allChannels) in
            
            self.allChannels = allChannels
            
            if self.channelSegmentOutlet.selectedSegmentIndex == 1 {
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
            
        }
    }
    
    private func downloadSubscribedChannels() {
        FirebaseChannelListener.shared.downloadSubscribedChannels { (subscribedChannels) in
            
            self.subscribedChannels = subscribedChannels
            
            if self.channelSegmentOutlet.selectedSegmentIndex == 0 {
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
            
        }
    }
    
    
    // MARK: - UIScrollViewDelegate
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if self.refreshControl!.isRefreshing {
            self.downloadAllChannels()
            self.refreshControl!.endRefreshing()
        }
    }
    
    
    // MARK: - Navigation
    private func showChannelView(channel: Channel) {
        
        let channelVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "channelView") as! ChannelDetailTableViewController
        
        channelVC.channel = channel
        channelVC.delegate = self
        self.navigationController?.pushViewController(channelVC, animated: true)
        
    }
    
    private func showChat(channel: Channel) {
        let channelChatVC = ChannelChatViewController(channel: channel)
        channelChatVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(channelChatVC, animated: true)
    }
    
    
//    // MARK: - delete Helper
//    private func deleteSubscribedChannel() {
//        
//        if FirebaseChannelListener.shared.channelListener == nil {
//            downloadSubscribedChannels()
//        }
//
//
//        for channel in subscribedChannels {
//
//            if channel.memberIds.contains(User.currentId!) {
//                var changedChannel: Channel = channel
//                changedChannel.memberIds.remove(at: changedChannel.memberIds.firstIndex(of: User.currentId!)!)
//                FirebaseChannelListener.shared.saveChannel(changedChannel)
//            }
//
//            if channel.adminId == User.currentId {
//                var changedChannel: Channel = channel
//                FirebaseChannelListener.shared.deleteChannel(changedChannel)
//            }
//
//
//        }
//    }
    

}

extension ChannelsTableViewController: ChannelDetailTableViewControllerDelegate {
    func didClickFollow() {
        // refresh allChannels
        self.downloadAllChannels()
    }
    
}
