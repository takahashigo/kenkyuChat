//
//  DeleteConfirmModalViewController.swift
//  iMessager
//
//  Created by 高橋悟生 on 2023/02/06.
//

import UIKit
import ProgressHUD


class DeleteConfirmModalViewController: UIViewController {
    

    @IBOutlet weak var modalView: UIView!
    
    // MARK: - IBActions
    @IBAction func cancelButtonPressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func nextButtonPressed(_ sender: UIButton) {
        // channel delete
        FirebaseChannelListener.shared.deleteChannelsAfterAccountDelete()
        // message delete
        FirebaseMessageListener.shared.deleteMessagesAfterAccountDelete()
        // recent delete
        FirebaseRecentListener.shared.deleteRecentsAfterAccountDelete()
        // typing delete
        FirebaseTypingListener.shared.deleteTypingsAfterAccountDelete()
        // channelRequest delete
        FirebaseChannelRequestListener.shared.deleteChannelRequestsAfterAccountDelete()
        // user delete
        FirebaseUserListener.shared.deleteUser { error in
            if error == nil {
                ProgressHUD.showSuccess("アカウントを削除しました")
                let loginView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(identifier: "loginView")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    loginView.modalPresentationStyle = .fullScreen
                    self.present(loginView, animated: true, completion: nil)
                }
            } else {
                ProgressHUD.showFailed("アカウントの削除に失敗しました")
            }
        }
    }
    
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.7)
        modalView.layer.cornerRadius = 10
    }
    

}
