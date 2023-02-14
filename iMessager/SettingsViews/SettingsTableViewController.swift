//
//  SettingsTableViewController.swift
//  iMessager
//
//  Created by 高橋悟生 on 2023/01/26.
//

import UIKit
import ProgressHUD

class SettingsTableViewController: UITableViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var appVersionLabel: UILabel!
    @IBOutlet weak var channelRequestLabel: UIButton!
    @IBOutlet weak var introductionLabel: UILabel!
    
    
    // MARK: - IBActions
    @IBAction func tellAFriendButtonPressed(_ sender: UIButton) {
        FirebaseUserListener.shared.resetPasswordFor(email: User.currentUser!.email) { error in
            if error == nil {
                ProgressHUD.showSuccess("確認メールを送信いたしました")
            } else {
//                ProgressHUD.showFailed(error!.localizedDescription)
                ProgressHUD.showFailed("パスワードの再設定に失敗しました")
            }
        }
    }
    
    
    @IBAction func logOutButtonPressed(_ sender: UIButton) {
        
        FirebaseUserListener.shared.logOutCurrentUser { error in
            
            if error == nil {
                let loginView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(identifier: "loginView")
                
                DispatchQueue.main.async {
                    loginView.modalPresentationStyle = .fullScreen
                    self.present(loginView, animated: true, completion: nil)
                }
            }
            
        }
        
        
    }
    
    
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        showUserInfo()
        fetchChannelRequestCount()
    }
    
    
    // MARK: - TableView Delegates
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor(named: "tableviewBackgroundColor")
        
        return headerView
    }
    
    // sections distance
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        print("\(indexPath.section), \(indexPath.row)")
        
        if indexPath.section == 0 && indexPath.row == 0 {
            performSegue(withIdentifier: "settingsToEditProfileSeg", sender: self)
        } 

        
    }
    
    
    
    // MARK: - updateUI
    private func showUserInfo() {
        if let user = User.currentUser {
            usernameLabel.text = user.username
            statusLabel.text = user.status
            introductionLabel.text = user.introduction
            appVersionLabel.text = "バージョン \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")"
            
            if user.avatarLink != "" {
                // download and set avatar image
                FileStorage.downloadImage(imageUrl: user.avatarLink) { (avatarImage) in
                    self.avatarImageView.image = avatarImage?.circleMasked
                }
            } else {
                self.avatarImageView.image = UIImage(named: "avatar")
            }
            
            
        }
    }
    
    
    // MARK: - Fetch channelRequestCount
    private func fetchChannelRequestCount() {
        FirebaseChannelRequestListener.shared.downloadRequestChannelsFromFirebase { allChannelRequests in
            self.channelRequestLabel.setTitle("トピック参加許可依頼（未処理：\(allChannelRequests.count)件）", for: .normal)
            
            self.tableView.reloadData()
        }
    }
    
}
