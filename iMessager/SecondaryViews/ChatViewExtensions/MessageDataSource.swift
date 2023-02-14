//
//  MessageDataSource.swift
//  iMessager
//
//  Created by 高橋悟生 on 2023/01/28.
//

import Foundation
import MessageKit


// MARK: - ChatViewController Extension
extension ChatViewController: MessagesDataSource {
    func currentSender() -> MessageKit.SenderType {
        return currentUser
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> MessageKit.MessageType {
        // message is different section in table
        return mkMessages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        return mkMessages.count
    }
    
    // MARK: - cell top labels
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        
        if indexPath.section % 3 == 0 {
            
            let showLoadMore = (indexPath.section == 0) && (allLocalMessages.count > displayingMessagesCount)
            let text = showLoadMore ? "もっと見る" : MessageKitDateFormatter.shared.string(from: message.sentDate)
            let font = showLoadMore ? UIFont.systemFont(ofSize: 13) : UIFont.boldSystemFont(ofSize: 10)
            let color = showLoadMore ? UIColor.lightGray : UIColor.darkGray
            
            return NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: color])
            
        }
        
        return nil
        
    }
    
//    // MARK: - message top labels
//    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
//        let font = UIFont.boldSystemFont(ofSize: 10)
//        let color = UIColor.darkGray
//            return NSAttributedString(
//                string: mkMessages[indexPath.section],
//                attributes:  [.font: font, .foregroundColor: color])
//    }
    
    
    // MARK: - cell bottom label
    func cellBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        
        if isFromCurrentSender(message: message) {
            let message = mkMessages[indexPath.section]
//            let status = indexPath.section == mkMessages.count - 1 ? message.status + " " + message.readDate.time() : ""
            let status = message.status + " " + message.readDate.time()
            return NSAttributedString(string: status, attributes: [.font: UIFont.boldSystemFont(ofSize: 10), .foregroundColor: UIColor.darkGray])
            
        } else {
            let message = mkMessages[indexPath.section]
//            let status = indexPath.section == mkMessages.count - 1 ? message.status + " " + message.readDate.time() : ""
            let status = message.readDate.time()
            return NSAttributedString(string: status, attributes: [.font: UIFont.boldSystemFont(ofSize: 10), .foregroundColor: UIColor.darkGray])
        }
    }
    
    // MARK: - Message bottom label
    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        
//        if indexPath.section != mkMessages.count - 1 {
//            return NSAttributedString(string: message.sentDate.time(), attributes: [.font: UIFont.boldSystemFont(ofSize: 10), .foregroundColor: UIColor.darkGray])
//        }
        
        return nil
        
    }
    
}


// MARK: - ChannelChatViewController Extension
extension ChannelChatViewController: MessagesDataSource {
    func currentSender() -> MessageKit.SenderType {
        return currentUser
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> MessageKit.MessageType {
        // message is different section in table
        return mkMessages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        return mkMessages.count
    }
    
    // MARK: - cell top labels
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        
        if indexPath.section % 3 == 0 {
            
            let showLoadMore = (indexPath.section == 0) && (allLocalMessages.count > displayingMessagesCount)
            let text = showLoadMore ? "もっと見る" : MessageKitDateFormatter.shared.string(from: message.sentDate)
            let font = showLoadMore ? UIFont.systemFont(ofSize: 13) : UIFont.boldSystemFont(ofSize: 10)
            let color = showLoadMore ? UIColor.lightGray : UIColor.darkGray
            
            return NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: color])
            
        }
        
        return nil
        
    }
    
    
    // MARK: - Message top label
    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
            return NSAttributedString(
                string: mkMessages[indexPath.section].sender.displayName,
                attributes: [.font: UIFont.systemFont(ofSize: 12.0),
                             .foregroundColor: UIColor.systemGray])
        }
    
    // MARK: - cell bottom label
//    func cellBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
//
//        if isFromCurrentSender(message: message) {
//            let message = mkMessages[indexPath.section]
//            let status = indexPath.section == mkMessages.count - 1 ? message.status + " " + message.readDate.time() : ""
//            return NSAttributedString(string: status, attributes: [.font: UIFont.boldSystemFont(ofSize: 10), .foregroundColor: UIColor.darkGray])
//
//        }
//
//        return nil
//
//    }
    
    // MARK: - Message bottom label
    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        
        return NSAttributedString(string: message.sentDate.time(), attributes: [.font: UIFont.boldSystemFont(ofSize: 10), .foregroundColor: UIColor.darkGray])
        
    }
    
}
