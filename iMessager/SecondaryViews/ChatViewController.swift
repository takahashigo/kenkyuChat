//
//  ChatViewController.swift
//  iMessager
//
//  Created by 高橋悟生 on 2023/01/28.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import Gallery
import RealmSwift
import MessageUI



class ChatViewController: MessagesViewController, MFMailComposeViewControllerDelegate {
    
    // MARK: - Views
    let leftBarButtonView: UIView = {
        return UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
    }()
    
    let titleLabel: UILabel = {
        let title = UILabel(frame: CGRect(x: 5, y: 0, width: 180, height: 25))
        title.textAlignment = .left
        title.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        title.adjustsFontSizeToFitWidth = true
        return title
    }()
    
    let subTitleLabel: UILabel = {
        let subTitle = UILabel(frame: CGRect(x: 5, y: 22, width: 180, height: 20))
        subTitle.textAlignment = .left
        subTitle.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        subTitle.adjustsFontSizeToFitWidth = true
        return subTitle
    }()
    
    
    // MARK: - Vars
    private var chatId = ""
    private var recipientId = ""
    private var recipientName = ""
    var recent: RecentChat?
    var mkMessages: [MKMessage] = []
    var allLocalMessages: Results<LocalMessage>!
    var displayingMessagesCount = 0
    var maxMessageNumber = 0
    var minMessageNumber = 0
    var typingCounter = 0
    var gallery: GalleryController!
    var longPressGesture: UILongPressGestureRecognizer!
    var audioFileName = ""
    var audioDuration: Date!
    var updateMessage: LocalMessage?
    
    // MARK: - lazy
    open lazy var audioController = BasicAudioController(messageCollectionView: messagesCollectionView)
    
    
    // MARK: - Lets
    let currentUser = MKSender(senderId: User.currentId!, displayName: User.currentUser!.username)
    let refreshController = UIRefreshControl()
    let micButton = InputBarButtonItem()
    let realm = try! Realm()
    
    // MARK: - Listenr
    var notificationToken: NotificationToken?
    
    
    
    // MARK: - Inits
    init(chatId: String, recipientId: String, recipientName: String) {
        super.init(nibName: nil, bundle: nil)
        
        self.chatId = chatId
        self.recipientId = recipientId
        self.recipientName = recipientName
        
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: - View LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        
        createTypingObserver()
        
        configureLeftBarButton()
        configureCustomTitle()
        
        configureMessageCollectionView()
        configureGestureRecognizer()
        configureMessageInputBar()
        configureMenu()
        updateMicButtonStatus(show: true)
        

        loadChats()
        listenForNewChats()
        listenForReadStatusChange()
        
        
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        FirebaseRecentListener.shared.resetRecentCounter(chatRoomId: chatId)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        FirebaseRecentListener.shared.resetRecentCounter(chatRoomId: chatId)
        audioController.stopAnyOngoingPlaying()
    }
    
    
    
    // MARK: - Configurations
    private func configureMessageCollectionView() {
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messageCellDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messagesLayoutDelegate = self
        
        scrollsToBottomOnKeyboardBeginsEditing = true
        maintainPositionOnKeyboardFrameChanged = true
        
        messagesCollectionView.refreshControl = refreshController
    }
    
    private func configureGestureRecognizer() {
        longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(recordAudio))
        longPressGesture.minimumPressDuration = 0.5
        longPressGesture.delaysTouchesBegan = true
        
    }
    
    
    private func configureMessageInputBar() {
        
        // レシーバーが存在するかチェック
        FirebaseUserListener.shared.checkExistingUser(userId: recipientId, completion: { exist in
            print(exist)
            self.messageInputBar.isHidden = !exist
            self.messageInputBar.inputTextView.isHidden = !exist
        })
        
        // ブロックされているかチェック
        FirebaseUserListener.shared.checkBlockedSender(userId: recipientId) { isBlocked in
            if isBlocked {
                self.messageInputBar.inputTextView.placeholder = "ブロックされています"
            } else {
                
                // ログインユーザーがブロックしているかチェック
                if User.currentUser!.blockList.contains(self.recipientId) {
                          self.messageInputBar.inputTextView.placeholder = "ブロックしています"
                          print("block")
                      } else {
                          self.messageInputBar.delegate = self
                          
                          let attachButton = InputBarButtonItem()
                          attachButton.image = UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(pointSize: 24))
                          attachButton.tintColor = .black
                          attachButton.setSize(CGSize(width: 24, height: 36), animated: false)
                          
                          attachButton.onTouchUpInside { item in
                              self.actionAttachMessage()
                          }
                          self.messageInputBar.inputTextView.placeholder = "メッセージ"
                          
                          self.micButton.image = UIImage(systemName: "mic.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 24))
                          self.micButton.setSize(CGSize(width: 24, height: 36), animated: false)
                          self.micButton.tintColor = .black
                          //  gesture recognizer
                          self.micButton.addGestureRecognizer(self.longPressGesture)
                          
                          self.messageInputBar.setStackViewItems([attachButton], forStack: .left, animated: false)
                          
                          self.messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
                          self.messageInputBar.setRightStackViewWidthConstant(to: 36.0, animated: false)
                          self.messageInputBar.inputTextView.isImagePasteEnabled = false
                          self.messageInputBar.shouldAutoUpdateMaxTextViewHeight = false
                          self.messageInputBar.maxTextViewHeight = 144.0
                          self.messageInputBar.sendButton.title = "送信"
                          
                          self.messageInputBar.backgroundView.backgroundColor = .systemBackground
                          self.messageInputBar.inputTextView.backgroundColor = .systemBackground
                      }
                
                
                
                
            }
        }
        
//
        

        
    }
    
    func configureMenu() {
        // 長押し設定
        let hiddenMenuItem = UIMenuItem(title: "非表示", action: #selector(MessageCollectionViewCell.hide(_:)))
        let reportMenuItem = UIMenuItem(title: "通報", action: #selector(MessageCollectionViewCell.report(_:)))
        
        UIMenuController.shared.menuItems = [reportMenuItem, hiddenMenuItem]
    }
    
    // update micBtn
    func updateMicButtonStatus(show: Bool) {
        
        if show {
            messageInputBar.setStackViewItems([micButton], forStack: .right, animated: false)
            messageInputBar.setRightStackViewWidthConstant(to: 30, animated: false)
        } else {
            messageInputBar.setStackViewItems([messageInputBar.sendButton], forStack: .right, animated: false)
            messageInputBar.setRightStackViewWidthConstant(to: 55, animated: false)
        }
        
    }
    
    // chevron.left append
    private func configureLeftBarButton() {
        self.navigationItem.leftBarButtonItems = [UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(self.backButtonPressed))]
    }
    
    // title append
    private func configureCustomTitle() {
        subTitleLabel.textColor = .darkGray
        
        leftBarButtonView.addSubview(titleLabel)
        leftBarButtonView.addSubview(subTitleLabel)
        
        let leftBarButtonItem = UIBarButtonItem(customView: leftBarButtonView)
        
        self.navigationItem.leftBarButtonItems?.append(leftBarButtonItem)
        
        titleLabel.text = recipientName
        
    }
    
    
    
    
    
    // MARK: - Load Chats(only chatRoom data)
    private func loadChats() {
        
        let predicate = NSPredicate(format: "chatRoomId = %@ AND NOT (%@ IN hideMemberIds)", argumentArray: [chatId, User.currentId!])
//        let predicate = NSPredicate(format: "chatRoomId = %@", chatId)
        
        allLocalMessages = realm.objects(LocalMessage.self).filter(predicate).sorted(byKeyPath: kDATE, ascending: true)
        
        // ローカルデータがなければ、 firestore(Remote Database) -> Realm(Local Database) save
        if allLocalMessages.isEmpty {
            checkForOldChats()
        }
        
        notificationToken = allLocalMessages.observe({ (changes: RealmCollectionChange) in
            
            switch changes {
            case .initial:
                self.insertMessages()
                self.messagesCollectionView.reloadData()
                self.messagesCollectionView.scrollToBottom(animated: true)
            case .update(_, _, let insertions, let modifications):
                
                for index in insertions {
                    //  mkMessageに変換
//                    if !self.allLocalMessages[index].hideMemberIds.contains(User.currentId!) {
                        print("insertion")
                        self.insertMessage(self.allLocalMessages[index])
                        self.messagesCollectionView.reloadData()
                        self.messagesCollectionView.scrollToBottom(animated: false)
//                    }
                    
                }
                
                // 修正の時
                for i in modifications {
                    self.messagesCollectionView.reloadData()
                    self.messagesCollectionView.scrollToBottom(animated: false)
                }
            
            
            case .error(let error):
                print("Error on new insertion", error.localizedDescription)
            }
            
        })
    }
    
    private func listenForNewChats() {
        FirebaseMessageListener.shared.listenForNewChat(User.currentId!, collectionId: chatId, lastMessageDate: lastMessageDate())
    }
    
    private func checkForOldChats() {
        FirebaseMessageListener.shared.checkForOldChats(User.currentId!, collectionId: chatId)
    }
    
    
    
    // MARK: - convert mkMesage
    private func listenForReadStatusChange() {
        
        FirebaseMessageListener.shared.listenForReadStatusChange(User.currentId!, collectionId: chatId) { (updatedMessage) in
            if updatedMessage.status != kSENT {
                // locally save (Realm), view reload, only readStatus update
                self.updateMessage(updatedMessage)
            }
        }
        
    }
    
    private func insertMessages() {
        // oldest ----- min---max min---max min--->max lastet
        maxMessageNumber = allLocalMessages.count - displayingMessagesCount
        minMessageNumber = maxMessageNumber - kNUMBEROFMESSAGES
        
        if minMessageNumber < 0 {
            minMessageNumber = 0
        }
        
        for i in minMessageNumber ..< maxMessageNumber {
            insertMessage(allLocalMessages[i])
        }
    }
    
    private func insertMessage(_ localMessage: LocalMessage) {
        
        if localMessage.senderId != User.currentId {
            // 既読にする
            markMessageAsRead(localMessage)
        }
        
        let incoming = IncomingMessage(self)
        self.mkMessages.append(incoming.createMessage(localMessage: localMessage)!)
        displayingMessagesCount += 1
    }
    
    
    // MARK: - Load More Messages
    private func loadMoreMessages(maxNumber: Int, minNumber: Int) {
        //        ------------ new_min-----new_max old_min-----old_max
        maxMessageNumber = minMessageNumber - 1
        minMessageNumber = maxMessageNumber - kNUMBEROFMESSAGES
        
        if minMessageNumber < 0 {
            minMessageNumber = 0
        }
        
        for i in (minMessageNumber ... maxMessageNumber).reversed() {
            insertOlderMessage(allLocalMessages[i])
        }
    }
    
    private func insertOlderMessage(_ localMessage: LocalMessage) {
        let incoming = IncomingMessage(self)
        self.mkMessages.insert(incoming.createMessage(localMessage: localMessage)!, at: 0)
        displayingMessagesCount += 1
    }
    
    private func markMessageAsRead(_ localMessage: LocalMessage) {
        
        if localMessage.senderId != User.currentId && localMessage.status != kREAD {
            FirebaseMessageListener.shared.updateMessageInFirebase(localMessage, memberIds: [User.currentId!, recipientId])
        }
    }
    
    
    // MARK: - Actions
    func messageSend(text: String?, photo: UIImage?, video: Video?, audio: String?, location: String?, audioDuration: Float = 0.0) {
        
        OutgoingMessage.send(chatId: chatId, text: text, photo: photo, video: video, audio: audio, audioDuration: audioDuration, location: location, memberIds: [User.currentId!, recipientId], receiverUserId: recipientId)
        
    }
    
    // MARK: - message update(hideMemberIds)
    //TODO: - hideMemberIds
    
    
    @objc func backButtonPressed() {
        //  RecentChat削除
        FirebaseRecentListener.shared.resetRecentCounter(chatRoomId: chatId)
        //  listeners削除
        removeListeners()
        self.navigationController?.popViewController(animated: true)
    }
    
    private func actionAttachMessage() {
        
        messageInputBar.inputTextView.resignFirstResponder()
        
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        
        let takePhotoOrVideo = UIAlertAction(title: "カメラ", style: .default) { (alert) in
//            print("show camera")
            self.showImageGallery(camera: true)
        }
        
        let shareMedia = UIAlertAction(title: "画像・動画を選択", style: .default) { (alert) in
//            print("show library")
            self.showImageGallery(camera: false)
        }
        
        let shareLocation = UIAlertAction(title: "位置情報を共有", style: .default) { (alert) in
//            print("share location")
            if let _ = LocationManager.shared.currentLocation {
                self.messageSend(text: nil, photo: nil, video: nil, audio: nil, location: kLOCATION)
            }
        }
        
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: nil)
        
        takePhotoOrVideo.setValue(UIImage(systemName: "camera"), forKey: "image")
        shareMedia.setValue(UIImage(systemName: "photo.fill"), forKey: "image")
        shareLocation.setValue(UIImage(systemName: "mappin.and.ellipse"), forKey: "image")
        
        optionMenu.addAction(takePhotoOrVideo)
        optionMenu.addAction(shareMedia)
        optionMenu.addAction(shareLocation)
        optionMenu.addAction(cancelAction)
        
        self.present(optionMenu, animated: true, completion: nil)
        
    
    }
    
    
    // MARK: - update Typing indicator
    func createTypingObserver() {
        FirebaseTypingListener.shared.createTypingObserver(chatRoomId: chatId) { (isTyping) in
            DispatchQueue.main.async {
                self.updateTypingIndicator(isTyping)
            }
        }
    }
    
    func typingIndicatorUpdate() {
        
        typingCounter += 1
        FirebaseTypingListener.saveTypingCounter(typing: true, chatRoomId: chatId)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // typingを止める
            self.typingCounterStop()
        }
        
    }
    
    func typingCounterStop() {
        typingCounter -= 1
        
        if typingCounter == 0 {
            FirebaseTypingListener.saveTypingCounter(typing: false, chatRoomId: chatId)
        }
    }
    
    // タイピングのドキュメントが更新中に以下の関数を実行
    func updateTypingIndicator(_ show: Bool) {
        subTitleLabel.text = show ? "\(self.recipientName)さんが入力中..." : ""
    }
    
    
    // MARK: - UIScrollViewDelegate
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        if refreshController.isRefreshing {
            if displayingMessagesCount < allLocalMessages.count {
                self.loadMoreMessages(maxNumber: maxMessageNumber, minNumber: minMessageNumber)
                messagesCollectionView.reloadDataAndKeepOffset()
            }
            refreshController.endRefreshing()
        }
        
    }
    
    
    // MARK: - UpdateReadMessageStatus
    private func updateMessage(_ localMessage: LocalMessage) {
        
        for index in 0 ..< mkMessages.count {
            
            let tempMessage = mkMessages[index]
            
            if localMessage.id == tempMessage.messageId {
                
                mkMessages[index].status = localMessage.status
                mkMessages[index].readDate = localMessage.readDate
                
                RealmManager.shared.saveToRealm(localMessage)
                
                if mkMessages[index].status == kREAD {
                    self.messagesCollectionView.reloadData()
                }
                
            }
            
        }
        
    }
    
    // MARK: - Helpers
    private func removeListeners() {
        FirebaseTypingListener.shared.removeTypingListener()
        FirebaseMessageListener.shared.removeListeners()
    }
    
    private func lastMessageDate() -> Date {
        let lastMessageDate = allLocalMessages.last?.date ?? Date()
        return Calendar.current.date(byAdding: .second, value: 1, to: lastMessageDate) ?? lastMessageDate
    }
    
    
    // MARK: - Gallery
    private func showImageGallery(camera: Bool) {
        
        gallery = GalleryController()
        gallery.delegate = self
        
        Config.tabsToShow = camera ? [.cameraTab] : [.imageTab, .videoTab]
        Config.Camera.imageLimit = 1
        Config.initialTab = .imageTab
        Config.VideoEditor.maximumDuration = 30
        
        self.present(gallery, animated: true, completion: nil)
        
    }
    
    
    // MARK: - AudioMessages
    @objc func recordAudio() {
        switch longPressGesture.state {
        case .began:
            
            audioDuration = Date()
            audioFileName = Date().stringDate()
            //  recordingする
            AudioRecorder.shared.startRecording(fileName: audioFileName)
            
        case .ended:
            
            // recording止める
            AudioRecorder.shared.finishRecording()
            
            if fileExistsAtPath(path: audioFileName + ".m4a") {
                
                let audioDuration = audioDuration.interval(ofComponent: .second, from: Date())
                
                //  messageを送る
                messageSend(text: nil, photo: nil, video: nil, audio: audioFileName, location: nil, audioDuration: audioDuration)
                
            } else {
                print("no audio file")
            }
            
            audioFileName = ""
            
        @unknown default:
            print("no audio file")
        }
    }
    
    // MARK: - long pressed, display menu setting
    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
            // actionは結構色んな種類(cooy, deleteなど)がデフォルトで定義されているので必要であればtrueにすればメニューに表示されるようになる
            switch action {
            case NSSelectorFromString("report:"):
                return true
            case NSSelectorFromString("hide:"):
                return true
            default:
                return super.collectionView(collectionView, canPerformAction: action, forItemAt: indexPath, withSender: sender)
            }
    }
    
    //TODO: - 通報処理と非表示処理の実装
    // MARK: - menu pressed, event occured
    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
            switch action {
            case NSSelectorFromString("report:"):
                // ここで通報処理する
                // HideReportDetailViewControllerに移動（aboutDescriptionがreport, deleteUserが送信者）(storyboardID: HideReportDetailView)
//                showReportOrHideModal(aboutDescription: "report", deleteUsername: allLocalMessages[indexPath.section].senderName, deleteUserId: allLocalMessages[indexPath.section].senderId, deleteMessage: allLocalMessages[indexPath.section])
                startMailer(subject: "\(allLocalMessages[indexPath.section].senderName)さんの不正コンテンツ提供について", messageBody: "\(allLocalMessages[indexPath.section].senderName)さんの不正コンテンツ提供について報告いたします。")
//                print("report: \(indexPath.section)")
                return
            case NSSelectorFromString("hide:"):
                //ここで非表示処理する
                // HideReportDetailViewControllerに移動（aboutDescriptionがreport, ）(storyboardID: HideReportDetailView)
//                showReportOrHideModal(aboutDescription: "hide", deleteUsername: allLocalMessages[indexPath.section].senderName, deleteUserId: allLocalMessages[indexPath.section].senderId, deleteMessage: allLocalMessages[indexPath.section])
                //TODO: - 非表示処理
                // Recent update（もし最後だったら）
                if allLocalMessages.count - 1 == indexPath.section && indexPath.section != 0 {
                    self.updateRecentChat(recent: self.recent!, lastMessage: allLocalMessages[indexPath.section - 1].message)
                } else if allLocalMessages.count - 1 == indexPath.section && indexPath.section == 0 {
                    self.updateRecentChat(recent: self.recent!, lastMessage: "")
                }
    
                // local save
                print(allLocalMessages.count)
                var memberIds = [User.currentId!, allLocalMessages[indexPath.section].senderId]
                try! realm.write {
                    self.updateMessage = allLocalMessages[indexPath.section]
                    allLocalMessages[indexPath.section].hideMemberIds.append(User.currentId!)
                }
                
                // firestore save
                for memberId in memberIds {
                    // firestore save
                    FirebaseMessageListener.shared.saveMessage(self.updateMessage!, memberId: memberId)
                }
                
                // 最後にmkMessageの削除とテーブルをリロード
                self.mkMessages.remove(at: indexPath.section)
                self.messagesCollectionView.reloadData()
                
                print("hide\(indexPath.section)")
                return
            default:
                super.collectionView(collectionView, performAction: action, forItemAt: indexPath, withSender: sender)
            }
    }
    
    // MARK: - Navigation
//    private func showReportOrHideModal(aboutDescription: String, deleteUsername: String, deleteUserId: String, deleteMessage: LocalMessage) {
//        let detailView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "HideReportDetailView") as! HideReportDetailViewController
//
//        detailView.aboutDescription = aboutDescription
//        detailView.deleteUsername = deleteUsername
//        detailView.deleteUserId = deleteUserId
//        detailView.deleteMessage = deleteMessage
//        detailView.modalPresentationStyle = .currentContext
//
//        self.navigationController?.present(detailView, animated: true)
//    }
    
    
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
    
    // MARK: - update RecentChat
    private func updateRecentChat(recent: RecentChat, lastMessage: String) {
        FirebaseRecentListener.shared.updateRecentItemWithOldMessage(recent: recent, lastMessage: lastMessage)
    }
    
    
}



// MARK: - Extension GalleryControllerDelegate
extension ChatViewController: GalleryControllerDelegate {
    func galleryController(_ controller: Gallery.GalleryController, didSelectImages images: [Gallery.Image]) {
        if images.count > 0 {
            images.first!.resolve { (image) in
                self.messageSend(text: nil, photo: image, video: nil, audio: nil, location: nil)
            }
        }
        
        controller.dismiss(animated: true, completion: nil)
    }
    
    func galleryController(_ controller: Gallery.GalleryController, didSelectVideo video: Gallery.Video) {
        self.messageSend(text: nil, photo: nil, video: video, audio: nil, location: nil)
        
        controller.dismiss(animated: true, completion: nil)
    }
    
    func galleryController(_ controller: Gallery.GalleryController, requestLightbox images: [Gallery.Image]) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func galleryControllerDidCancel(_ controller: Gallery.GalleryController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

// MARK: - Extension MassageCollectionViewCell
extension MessageCollectionViewCell {
    // イベント発火させるためのメソッド
    @objc func report(_ sender: Any?) {
        // Get the collectionView
        if let collectionView = self.superview as? UICollectionView {
            // Get indexPath
            if let indexPath = collectionView.indexPath(for: self) {
                // Trigger action
                collectionView.delegate?.collectionView?(collectionView, performAction: NSSelectorFromString("report:"), forItemAt: indexPath, withSender: sender)
            }
        }
    }
    
    @objc func hide(_ sender: Any?) {
        // Get the collectionView
        if let collectionView = self.superview as? UICollectionView {
            // Get indexPath
            if let indexPath = collectionView.indexPath(for: self) {
                // Trigger action
                collectionView.delegate?.collectionView?(collectionView, performAction: NSSelectorFromString("hide:"), forItemAt: indexPath, withSender: sender)
            }
        }
    }
}


