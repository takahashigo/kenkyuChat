//
//  ProfileTableViewController.swift
//  iMessager
//
//  Created by 高橋悟生 on 2023/01/27.
//

import UIKit

protocol updateUsers {
    func downloadUsers() -> Void
    func downloadBlockedUsers() -> Void
}

class ProfileTableViewController: UITableViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var introductionLabel: UILabel!
    @IBOutlet weak var talkOrUnBlockLabel: UILabel!
    
    
    // MARK: - Vars
    var user: User?
    var isBlocked: Bool?
    
    // MARK: - Lets
    var delegate: UsersTableViewController?
    
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        tableView.tableFooterView = UIView()
        talkOrUnBlockLabel.text = !isBlocked! ? "トークする" : "ブロックを解除する"
        setupUI()
    }
    
    
    // MARK: - Tableview Delegates
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        let headerView = UIView()
        headerView.backgroundColor = UIColor(named: "tableviewBackgroundColor")
        return headerView
    }
    
    // height layout
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 1 {
            if isBlocked! {
                var updatedUser = User.currentUser!
                guard let blockUserId = updatedUser.blockList.firstIndex(of: user!.id) as? Int else {
                    print("ブロックしているユーザーがいません")
                    return
                }
                
                updatedUser.blockList.remove(at: blockUserId)
                
                // save locally
                saveUserLocally(updatedUser)
                
                // save firestore
                FirebaseUserListener.shared.updateUserInFirebase(updatedUser)
                // delegate
                delegate?.downloadUsers()
                delegate?.downloadBlockedUsers()
                // go to allUsers
                self.navigationController?.popViewController(animated: true)
                
            } else {
                // チャットルームを作成、チャットルームに移動
                let chatId = startChat(user1: User.currentUser!, user2: user!)
                
                let privateChatView = ChatViewController(chatId: chatId, recipientId: user!.id, recipientName: user!.username)
                
                privateChatView.hidesBottomBarWhenPushed = true
                navigationController?.pushViewController(privateChatView, animated: true)
            }
            
        }
    }
    
    
    // MARK: - SetupUI
    private func setupUI() {
        
        if user != nil {
            self.title = user!.username
            usernameLabel.text = user!.username
            statusLabel.text = user!.status
            introductionLabel.text = user!.introduction
            
            if user!.avatarLink != "" {
                FileStorage.downloadImage(imageUrl: user!.avatarLink) { avatarImage in
                    self.avatarImageView.image = avatarImage?.circleMasked
                }
            } else {
                self.avatarImageView.image = UIImage(named: "avatar")
            }
        }
        
    }
    
}
