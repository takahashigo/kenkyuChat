//
//  HideReportDetailViewController.swift
//  iMessager
//
//  Created by 高橋悟生 on 2023/02/09.
//

import UIKit
import MessageUI


class HideReportDetailViewController: UIViewController, MFMailComposeViewControllerDelegate {
    
    // MARK: - Vars
    var aboutDescription: String?
    var deleteUsername: String?
    var deleteUserId: String?
    var deleteMessage: LocalMessage?
    var deleteChannel: Channel?
    
    // MARK: - IBOutlets
    @IBOutlet weak var descriptionLabel: UILabel!
    
    // MARK: - IBActions
    @IBAction func nextButtonPressed(_ sender: UIButton) {
        if aboutDescription == "report" {
            // メーラーを開く
            startMailer(subject: "\(deleteUsername!)さんの不正コンテンツ提供について", messageBody: "\(deleteUsername!)さんの不正コンテンツ提供について報告いたします。")
            
            dismiss(animated: true, completion: nil)
            
        } else if aboutDescription == "hide" {
            // hideMemberIdsに自分をいれる（OutgoingMessage.sendMessage(or sendChannelMessage)にLocalMessageの型の更新したメッセージデータとMemberId( or channel)を送れればいい)
            
            if let channel = deleteChannel {
                // channel ver
                // channelの場合は、deleteMessageとdeleteChannelを利用
                
            } else {
                // chat ver
                // chatの場合、MemberIdはdeleteUserIdと自分
            }
                
                
            
            
            
            
        }
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - view
    @IBOutlet weak var modalView: UIView!
    
    // MARK: - view life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

//        view.backgroundColor = .clear
        view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.7)
        modalView.layer.cornerRadius = 10
        
        configureLabel()
    }
    
    // MARK: - Configure
    func configureLabel() {
        if aboutDescription == "report" {
            if let username = deleteUsername {
                descriptionLabel.text = "\(username)さんが不適切なメッセージを送信したとして、管理者に通報しますか？"
            }
        } else if aboutDescription == "hide" {
            descriptionLabel.text = "このメッセージを非表示にしますか？"
        }
    }
    
    // MARK: - start mailer
    func startMailer(subject: String, messageBody: String) {
            //メールを送信できるかチェック
            if MFMailComposeViewController.canSendMail()==false {
                print("Email Send Failed")
                return
            }

            var mailViewController = MFMailComposeViewController()
            var toRecipients = ["go20001104@gmail.com"]
//            var CcRecipients = ["cc@1gmail.com","Cc2@1gmail.com"]
//            var BccRecipients = ["Bcc@1gmail.com","Bcc2@1gmail.com"]


            mailViewController.mailComposeDelegate = self
            mailViewController.setSubject(subject)
            mailViewController.setToRecipients(toRecipients) //宛先メールアドレスの表示
//            mailViewController.setCcRecipients(CcRecipients)
//            mailViewController.setBccRecipients(BccRecipients)
            mailViewController.setMessageBody(messageBody, isHTML: false)

        self.present(mailViewController, animated: true, completion: nil)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            switch result {
            case .cancelled:
                print("Email Send Cancelled")
                break
            case .saved:
                print("Email Saved as a Draft")
                break
            case .sent:
                print("Email Sent Successfully")
                break
            case .failed:
                print("Email Send Failed")
                break
            default:
                break
            }
            controller.dismiss(animated: true, completion: nil)
        }
    
    
    
    
    

    

}
