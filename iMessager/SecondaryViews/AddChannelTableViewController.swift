//
//  AddChannelTableViewController.swift
//  iMessager
//
//  Created by 高橋悟生 on 2023/01/31.
//

import UIKit
import Gallery
import ProgressHUD

class AddChannelTableViewController: UITableViewController, updateChannelMemberIds {

    // MARK: - IBOutlets
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var aboutTextView: UITextView!
    
    // MARK: - Vars
    var gallery: GalleryController!
    var tapGesture = UITapGestureRecognizer()
    var avatarLink = ""
    var channelId = UUID().uuidString
    var memberIds: [String] = [User.currentId!]
    var channelToEdit: Channel?
    
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        tableView.tableFooterView = UIView()
        
        configureGestures()
        configureLeftBarButton()
        
        if channelToEdit != nil {
            configureEditingView()
        }
        
    }
    
    
    // MARK: - IBActions
    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        
        if nameTextField.text != "" {
            channelToEdit != nil ? editChannel() : saveChannel()
        } else {
            ProgressHUD.showError("トピック名を入力してください")
        }
         
    }
    
    @objc func avatarImageTap() {
        showGallery()
    }
    
    @objc func backButtonPressed() {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    // MARK: - Configuration
    private func configureGestures() {
        tapGesture.addTarget(self, action: #selector(avatarImageTap))
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.addGestureRecognizer(tapGesture)
    }
    
    private func configureLeftBarButton() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(backButtonPressed))
    }
    
    private func configureEditingView() {
        self.nameTextField.text = channelToEdit!.name
        self.channelId = channelToEdit!.id
        self.aboutTextView.text = channelToEdit!.aboutChannel
        self.avatarLink = channelToEdit!.avatarLink
        self.memberIds = channelToEdit!.memberIds
        self.title = "トピック編集"
        
        setAvatar(avatarLink: channelToEdit!.avatarLink)
    }
    
    
    // MARK: - Save Channel
    private func saveChannel() {
        
        let channel = Channel(id: channelId, name: nameTextField.text!, adminId: User.currentId!, memberIds: memberIds, avatarLink: avatarLink, aboutChannel: aboutTextView.text!)
        
        // firestoreに保存
        FirebaseChannelListener.shared.saveChannel(channel)
        
        self.navigationController?.popViewController(animated: true)
        
    }
    
    // MARK: - Edit Channel
    private func editChannel() {
        
        channelToEdit!.name = nameTextField.text!
        channelToEdit!.aboutChannel = aboutTextView.text
        channelToEdit!.avatarLink = avatarLink
        channelToEdit!.memberIds = memberIds
        
        
        // firestoreに保存
        FirebaseChannelListener.shared.saveChannel(channelToEdit!)
        
        self.navigationController?.popViewController(animated: true)
        
    }
    
    
    // MARK: - Gallery
    private func showGallery() {
        
        self.gallery = GalleryController()
        self.gallery.delegate = self
        Config.tabsToShow = [.imageTab, .cameraTab]
        Config.Camera.imageLimit = 1
        Config.initialTab = .imageTab
        
        self.present(gallery, animated: true, completion: nil)
        
    }
    
    
    // MARK: - Set Avatar
    private func uploadAvatarImage(_ image: UIImage) {
        
        let fileDirectory = "Avatars/" + "_\(channelId)" + ".jpg"
        
        //save locallry
        FileStorage.saveFileLocally(fileData: image.jpegData(compressionQuality: 0.7)! as NSData , fileName: self.channelId)
        
        // save firestore
        FileStorage.uploadImage(image, directory: fileDirectory) { (avatarLink) in
            self.avatarLink = avatarLink ?? ""
        }
        
    }
    
    private func setAvatar(avatarLink: String) {
        
        if avatarLink != "" {
            FileStorage.downloadImage(imageUrl: avatarLink) { (avatarImage) in
                
                DispatchQueue.main.async {
                    self.avatarImageView.image = avatarImage?.circleMasked
                }
                
            }
        } else {
            self.avatarImageView.image = UIImage(named: "avatar")
        }
        
    }
    
    
    // MARK: - table delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row == 2 {
            showChannelMembers()
        }
    }
    
    // MARK: - delegate
    func updateMemberIds(memberIds: [String]) {
        self.memberIds = memberIds
    }
    
    // MARK: - Navigation
    private func showChannelMembers() {
        
        let channelMembersView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "ChannelMembersView") as! ChannelMemberTableViewController
        
        channelMembersView.memberIds = memberIds
        channelMembersView.delegate = self
        self.navigationController?.pushViewController(channelMembersView, animated: true)
        
    }
    
    
}

extension AddChannelTableViewController: GalleryControllerDelegate {
    func galleryController(_ controller: Gallery.GalleryController, didSelectImages images: [Gallery.Image]) {
        
        if images.count > 0 {
            
            images.first!.resolve { (icon) in
                
                if icon != nil {
                    //upload image
                    self.uploadAvatarImage(icon!)
                    //set avatar image
                    self.avatarImageView.image = icon!.circleMasked
                } else {
                    ProgressHUD.showFailed("画像の選択に失敗しました")
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
