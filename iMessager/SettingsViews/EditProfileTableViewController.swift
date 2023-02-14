//
//  EditProfileTableViewController.swift
//  iMessager
//
//  Created by 高橋悟生 on 2023/01/27.
//

import UIKit
import Gallery
import ProgressHUD


class EditProfileTableViewController: UITableViewController {
    
    // MARK: - Vars
    var gallery: GalleryController!
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var introductionTextFieldOutlet: UITextField!
    
    
    // MARK: - IBActions
    
    @IBAction func editButtonPressed(_ sender: UIButton) {
        showImageGallery()
    }
    
    
    
    // MARK: - View life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        
        configureTextField()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        showUserInfo()
    }
    
    // MARK: - TableView Delegates
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor(named: "tableviewBackgroundColor")
        
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? 0.0 : 30.0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        // show status view
        if indexPath.section == 1 && indexPath.row == 0 {
            performSegue(withIdentifier: "editProfileToStatusSeg", sender: self)
        }
        
        
    }
    
    // MARK: - UpdateUI
    private func showUserInfo() {
        
        if let user = User.currentUser {
            usernameTextField.text = user.username
            statusLabel.text = user.status
            introductionTextFieldOutlet.text = user.introduction
            
            if user.avatarLink != "" {
                //set avatar
                FileStorage.downloadImage(imageUrl: user.avatarLink) { (avatarImage) in
                    self.avatarImageView.image = avatarImage?.circleMasked
                }
            } else {
                self.avatarImageView.image = UIImage(named: "avatar")
            }
        }
    }
    
    // MARK: - Configure
    private func configureTextField() {
        usernameTextField.delegate = self
        usernameTextField.clearButtonMode = .whileEditing
        
        introductionTextFieldOutlet.delegate = self
        introductionTextFieldOutlet.clearButtonMode = .whileEditing
    }
    
    
    // MARK: - Gallery
    private func showImageGallery() {
        
        self.gallery = GalleryController()
        self.gallery.delegate = self
        
        Config.tabsToShow = [.imageTab, .cameraTab]
        Config.Camera.imageLimit = 1
        Config.initialTab = .imageTab
        
        self.present(gallery, animated: true, completion: nil)
    }
    
    // MARK: - upload Images
    private func uploadAvatarImage(_ image: UIImage) {
        
        let fileDirectory = "Avatars/" + "_\(User.currentId!)" + ".jpg"
        
        FileStorage.uploadImage(image, directory: fileDirectory) { (avatarLink) in
            
            if var user = User.currentUser {
                user.avatarLink = avatarLink ?? ""
                // locally save
                saveUserLocally(user)
                // firestore save
                FirebaseUserListener.shared.saveUserToFirestore(user)
            }
            
            // Save image locally
            FileStorage.saveFileLocally(fileData: image.jpegData(compressionQuality: 1.0)! as NSData, fileName: User.currentId!)
            
        }
        
        
    }
    
    
    
}

// MARK: - UITextFieldDelegate
extension EditProfileTableViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == usernameTextField {
            
            if textField.text != "" {
                
                if var user = User.currentUser {
                    user.username = textField.text!
                    // locally save
                    saveUserLocally(user)
                    // firebase save
                    FirebaseUserListener.shared.saveUserToFirestore(user)
                    // update recent receiverName
                    FirebaseRecentListener.shared.updateRecentReceiverName(username: user.username)
                }
                
                textField.resignFirstResponder()
                return false
            }
        } else if textField == introductionTextFieldOutlet {
            if textField.text != "" {
                
                if var user = User.currentUser {
                    user.introduction = textField.text!
                    // locally save
                    saveUserLocally(user)
                    // firebase save
                    FirebaseUserListener.shared.saveUserToFirestore(user)
                }
                
                textField.resignFirstResponder()
                return false
            }
            
            
        }
        return true
        
    }
}


// MARK: - GalleryControllerDelegate
extension EditProfileTableViewController: GalleryControllerDelegate {
    func galleryController(_ controller: Gallery.GalleryController, didSelectImages images: [Gallery.Image]) {
        
        if images.count > 0 {
            images.first!.resolve { (avatarImage) in
                
                if avatarImage != nil {
                    self.uploadAvatarImage(avatarImage!)
                    self.avatarImageView.image = avatarImage?.circleMasked
                    
                } else {
                    ProgressHUD.showError("画像の選択に失敗いたしました")
                }
                
            }
        }
        
        controller.dismiss(animated: true, completion: nil)
        
    }
    
    func galleryController(_ controller: Gallery.GalleryController, didSelectVideo video: Gallery.Video) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func galleryController(_ controller: Gallery.GalleryController, requestLightbox images: [Gallery.Image]) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func galleryControllerDidCancel(_ controller: Gallery.GalleryController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    
}
