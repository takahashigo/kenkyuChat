//
//  ChannelTableViewController.swift
//  iMessager
//
//  Created by 高橋悟生 on 2023/01/31.
//

import UIKit
import ProgressHUD


protocol ChannelDetailTableViewControllerDelegate {
    func didClickFollow()
}

class ChannelDetailTableViewController: UITableViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var membersLabel: UILabel!
    @IBOutlet weak var aboutTextView: UITextView!
    
    // MARK: - Vars
    var channel: Channel!
    var delegate: ChannelDetailTableViewControllerDelegate?
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        tableView.tableFooterView = UIView()
        
        showChannelData()
        configureRightBarButton()
    }
    
    
    // MARK: - Configure
    private func showChannelData() {
        self.title = channel.name
        nameLabel.text = channel.name
        membersLabel.text = "\(channel.memberIds.count)人"
        aboutTextView.text = channel.aboutChannel
        setAvatar(avatarLink: channel.avatarLink)
    }
    
    private func configureRightBarButton() {
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "参加", style: .plain, target: self, action: #selector(followChannel))
        
    }
    
    // MARK: - Set Avatar
    private func setAvatar(avatarLink: String) {
        
        if avatarLink != "" {
            
            FileStorage.downloadImage(imageUrl: avatarLink) { (avatarImage) in
                DispatchQueue.main.async {
                    self.avatarImageView.image = avatarImage != nil ? avatarImage?.circleMasked : UIImage(named: "avatar")
                }
            }
            
        } else {
            self.avatarImageView.image = UIImage(named: "avatar")
        }
        
    }
    
    
    //TODO: - この関数を修正する（具体的には、channelrequestを作成＋ProgressHUD＋プッシュ通知）
    // MARK: - Actions
    @objc func followChannel() {
        //locally save
//        channel.memberIds.append(User.currentId!)
//        FirebaseChannelListener.shared.saveChannel(channel)
//        delegate?.didClickFollow()
//        self.navigationController?.popViewController(animated: true)
        
        FirebaseChannelRequestListener.shared.downloadIdentifyChannelRequests(channelId: channel.id, requestUserId: User.currentId!) { channelRequests in
            if channelRequests.count <= 0 {
                // fetch adminUsername
                FirebaseUserListener.shared.downloadUsersFromFirebase(withIds: [self.channel.adminId]) { allUsers in
                    
                    let adminUser = allUsers[0]
                    
                    // new request
                    var newChannelRequest: ChannelRequest = ChannelRequest(id: UUID().uuidString, channelId: self.channel.id, channelName: self.channel.name, receiveUserId: self.channel.adminId, receiveUsername: adminUser.username, requestUserId: User.currentId!, requestUsername: User.currentUser!.username)

                    
                    FirebaseChannelRequestListener.shared.saveChannelRequest(newChannelRequest)
                    
                    ProgressHUD.showSuccess("管理者に参加リクエストを送信しました。")
                    
                    // send pushNotification
                    PushNotificationService.shared.sendChannelRequestPushNotificationTo(userId: adminUser.id, title: "トピック参加依頼", body: "\(newChannelRequest.requestUsername)さんから\(newChannelRequest.channelName)への参加許可依頼があります。", channelRequest: newChannelRequest)
                    
                }
            } else {
                print(channelRequests.count)
                ProgressHUD.showFailed("既に参加リクエストを送信しています。")
            }
        }
        
    }
    
    // MARK: - table delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row == 2 {
            showChannelMembers()
        }
    }
    
    // MARK: - Navigation
    private func showChannelMembers() {
        
        let channelMembersView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "ChannelMembersView") as! ChannelMemberTableViewController
        
        channelMembersView.memberIds = channel.memberIds
        channelMembersView.isDetail = true
        self.navigationController?.pushViewController(channelMembersView, animated: true)
        
    }


}
