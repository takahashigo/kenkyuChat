//
//  FirebaseRecentListener.swift
//  iMessager
//
//  Created by 高橋悟生 on 2023/01/28.
//

import Foundation
import FirebaseFirestore

class FirebaseRecentListener {
    
    static let shared = FirebaseRecentListener()
    
    private init() {}
    
    func downloadRecentChatsFromFireStore(completion: @escaping (_ allRecents: [RecentChat]) -> Void) {
        
        FirebaseReference(.Recent).whereField(kSENDERID, isEqualTo: User.currentId).addSnapshotListener { (querySnapshot, error) in
            var recentChats: [RecentChat] = []
            
            guard let documents = querySnapshot?.documents else {
                print("no documents for recent chats")
                return
            }
            
            let allRecents = documents.compactMap { (queryDocumentSnapshot) -> RecentChat? in
                return try? queryDocumentSnapshot.data(as: RecentChat.self)
            }
            
            for recent in allRecents {
                if recent.lastMessage != "" {
                    recentChats.append(recent)
                }
            }
            
            recentChats.sort(by: { $0.date! > $1.date! })
            completion(recentChats)
            
        }
        
    }
    
    func resetRecentCounter(chatRoomId: String) {
        
        FirebaseReference(.Recent).whereField(kCHATROOMID, isEqualTo: chatRoomId).whereField(kSENDERID, isEqualTo: User.currentId).getDocuments { (querySnapshot, error) in
            
            guard let documents = querySnapshot?.documents else {
                print("no documents for recent")
                return
            }
            
            let allRecents = documents.compactMap { (queryDocumentSnapshot) -> RecentChat? in
                return try? queryDocumentSnapshot.data(as: RecentChat.self)
            }
            
            if allRecents.count > 0 {
                self.clearUnreadCounter(recent: allRecents.first!)
            }
            
        }
    }
    
    // external usage
    func updateRecents(chatRoomId: String, lastMessage: String) {
        
        FirebaseReference(.Recent).whereField(kCHATROOMID, isEqualTo: chatRoomId).getDocuments { (querySnapshot, error) in
            
            guard let documents = querySnapshot?.documents else {
                print("no documents for recent update")
                return
            }
            
            let allRecents = documents.compactMap { (queryDocumentSnapshot) -> RecentChat? in
                return try? queryDocumentSnapshot.data(as: RecentChat.self)
            }
            
            for recentChat in allRecents {
                self.updateRecentItemWithNewMessage(recent: recentChat, lastMessage: lastMessage)
            }
            
        }
        
    }
    
    private func updateRecentItemWithNewMessage(recent: RecentChat, lastMessage: String) {
        
        var tempRecent = recent
        
        if tempRecent.senderId != User.currentId {
            tempRecent.unreadCounter += 1
        }
        
        tempRecent.lastMessage = lastMessage
        tempRecent.date = Date()
        
        self.saveRecent(tempRecent)
        
    }
    
    func updateRecentItemWithOldMessage(recent: RecentChat, lastMessage: String) {
        
        var tempRecent = recent
        
        tempRecent.lastMessage = lastMessage
        
        self.saveRecent(tempRecent)
        
    }
    
    func clearUnreadCounter(recent: RecentChat) {
        var newRecent = recent
        newRecent.unreadCounter = 0
        self.saveRecent(newRecent)
    }
    
    
    func saveRecent(_ recent: RecentChat) {
        do {
            try FirebaseReference(.Recent).document(recent.id).setData(from: recent)
        } catch {
            print("Error saving recent chat", error.localizedDescription)
        }
    }
    
    func deleteRecent(_ recent: RecentChat) {
        FirebaseReference(.Recent).document(recent.id).delete()
        
    }
    
    // MARK: - delete user account
    func deleteRecentsAfterAccountDelete() {
        // receiverId is deletedUserId, recent deleted
        FirebaseReference(.Recent).whereField(kSENDERID, isEqualTo: User.currentId!).getDocuments { (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
                print("no documents for recent")
                return
            }
            
            let allRecents = documents.compactMap { (queryDocumentSnapshot) -> RecentChat? in
                return try? queryDocumentSnapshot.data(as: RecentChat.self)
            }
            
            for deleteRecent in allRecents {
                self.deleteRecent(deleteRecent)
            }
            
            
        }
        
        
        // senderId is change
        FirebaseReference(.Recent).whereField(kRECEIVERID, isEqualTo: User.currentId!).getDocuments { (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
                print("no documents for recent")
                return
            }
            
            var allRecents = documents.compactMap { (queryDocumentSnapshot) -> RecentChat? in
                return try? queryDocumentSnapshot.data(as: RecentChat.self)
            }
            
            for recent in allRecents {
                var nameChangeRecent = recent
                nameChangeRecent.receiverName = "メンバーがいません"
                nameChangeRecent.avatarLink = ""
                self.saveRecent(nameChangeRecent)
                
            }
            
            
        }
        
        
    }
    
    
    // MARK: - RecentChat receiverName update, after username update
    func updateRecentReceiverName(username: String) {
        FirebaseReference(.Recent).whereField(kRECEIVERID, isEqualTo: User.currentId!).getDocuments { (querySnapshot, error) in
            
            guard let documents = querySnapshot?.documents else {
                print("no documents for recent update")
                return
            }
            
            var allRecents = documents.compactMap { (queryDocumentSnapshot) -> RecentChat? in
                return try? queryDocumentSnapshot.data(as: RecentChat.self)
            }
            
            for recentChat in allRecents {
                var updateRecentChat = recentChat
                updateRecentChat.receiverName = username
                self.saveRecent(updateRecentChat)
            }
            
        }
        
        
    }
    
    
    
    
}
