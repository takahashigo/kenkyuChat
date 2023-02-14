//
//  FirebaseMessageListener.swift
//  iMessager
//
//  Created by 高橋悟生 on 2023/01/29.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

class FirebaseMessageListener {
    
    static let shared = FirebaseMessageListener()
    
    // MARK: - Listener(subscribe)
    var newChatListener: ListenerRegistration!
    var updatedChatListener: ListenerRegistration!
    
    
    
    private init() {}
    
    // MARK: - Subscription(new Chat: more than lastDate, addSnapshotListener, firestoreChange -> save Realm )
    func listenForNewChat(_ documentId: String, collectionId: String, lastMessageDate: Date){
        
        newChatListener = FirebaseReference(.Messages).document(documentId).collection(collectionId).whereField(kDATE, isGreaterThan: lastMessageDate)
            .addSnapshotListener({ (querySnapshot, error) in
                
                guard let snapshot = querySnapshot else { return }
                
                for change in snapshot.documentChanges {
                    
                    if change.type == .added {
                        
                        let result = Result {
                            try? change.document.data(as: LocalMessage.self)
                        }
                        
                        switch result {
                        case .success(let messageObject):
                            if let message = messageObject {
                                // because sender is me, don't save
                                if message.senderId != User.currentId {
                                    RealmManager.shared.saveToRealm(message)
                                }
                            } else {
                                print("Document doesn't exist")
                            }
                        case .failure(let error):
                            print("Error decoding local messages: \(error.localizedDescription)")
                        }
                        
                        
                    }
                    
                }
                
            })
        
    }
    
    
    // MARK: - Listen status(subscription)
    func listenForReadStatusChange(_ documentId: String, collectionId: String, completion: @escaping (_ updatedMessage: LocalMessage) -> Void) {
        
        updatedChatListener = FirebaseReference(.Messages).document(documentId).collection(collectionId).addSnapshotListener({ (querySnapshot, error) in
            
            guard let snapshot = querySnapshot else { return }
            
            for change in snapshot.documentChanges {
                
                if change.type == .modified {
                    let result = Result {
                        try? change.document.data(as: LocalMessage.self)
                    }
                    
                    switch result {
                    case .success(let messageObject):
                        if let message = messageObject {
                            completion(message)
                        } else {
                            print("Document does not exist in chat")
                        }
                    case .failure(let error):
                        print("Error decoding local message: ", error.localizedDescription)
                    }
                    
                }
                
            }
            
        })
        
    }
    
    
    // MARK: - get. in first load, because messages is empty, firestore -> Realm save
    func checkForOldChats(_ documentId: String, collectionId: String) {
        
        FirebaseReference(.Messages).document(documentId).collection(collectionId).getDocuments { (querySnapshot, error) in
            
            guard let documents = querySnapshot?.documents else {
                print("no documents for old chats")
                return
            }
            
            var oldMessages = documents.compactMap { (queryDocumentSnapshot) -> LocalMessage? in
                return try? queryDocumentSnapshot.data(as: LocalMessage.self)
            }
            
            oldMessages.sort(by: { $0.date < $1.date })
            
            for message in oldMessages {
                RealmManager.shared.saveToRealm(message)
            }
        }
        
    }
    
    
    // MARK: - Add, Update, Delete
    func saveMessage(_ message: LocalMessage, memberId: String) {
        
        do {
            let _ = try FirebaseReference(.Messages).document(memberId).collection(message.chatRoomId).document(message.id).setData(from: message)
        } catch {
            print("error saving message ", error.localizedDescription)
        }
        
    }
    
    func saveChannelMessage(_ message: LocalMessage, channel: Channel) {
        
        do {
            let _ = try FirebaseReference(.Messages).document(channel.id).collection(channel.id).document(message.id).setData(from: message)
        } catch {
            print("error saving message ", error.localizedDescription)
        }
        
    }
    
    
    // MARK: - UpdateMessageStatus
    func updateMessageInFirebase(_ message: LocalMessage, memberIds: [String]) {
        
        let values = [kSTATUS: kREAD, kREADDATE: Date()] as [String: Any]
        
        for userId in memberIds {
            FirebaseReference(.Messages).document(userId).collection(message.chatRoomId).document(message.id).updateData(values)
        }

    }
    
//    // MARK: - hideMember update
//    func updateHideMemberIdsInFirebase(_ message: LocalMessage) {
//
//        var updateHideMemberIds = message.hideMemberIds
//
//        if (updateHideMemberIds.contains(User.currentId!)) {
//            return
//        } else {
//            updateHideMemberIds.append(User.currentId!)
//        }
//
//        let value = [kHIDEMEMBERIDS: updateHideMemberIds] as [String: Any]
//
//        FirebaseReference(.Messages).document()
//
//
//    }
    
    
    func removeListeners() {
        self.newChatListener.remove()
        if self.updatedChatListener != nil {
            self.updatedChatListener.remove()
        }
    }
    
    // MARK: - delete Messages
    func deleteMessagesAfterAccountDelete() {
        FirebaseReference(.Messages).document(User.currentId!).delete()
    }
    
}
