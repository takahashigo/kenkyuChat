//
//  FirebaseTypingListener.swift
//  iMessager
//
//  Created by 高橋悟生 on 2023/01/30.
//

import Foundation
import FirebaseFirestore


class FirebaseTypingListener {
    
    static let shared = FirebaseTypingListener()
    
    var typingListenr: ListenerRegistration!
    
    private init() {}
    
    func createTypingObserver(chatRoomId: String, completion: @escaping (_ isTyping: Bool) -> Void) {
        
        typingListenr = FirebaseReference(.Typing).document(chatRoomId).addSnapshotListener({ (snapshot, error) in
            
            guard let snapshot = snapshot else { return }
            
            if snapshot.exists {
                
                for data in snapshot.data()! {
                    
                    if data.key != User.currentId {
                        completion(data.value as! Bool)
                    }
                    
                }
                
            } else {
                completion(false)
                FirebaseReference(.Typing).document(chatRoomId).setData([User.currentId!: false])
            }
            
        })
    }
    
    class func saveTypingCounter(typing: Bool, chatRoomId: String) {
        FirebaseReference(.Typing).document(chatRoomId).updateData([User.currentId!: typing])
    }
    
    func removeTypingListener() {
        self.typingListenr.remove()
    }
    
    // MARK: - Account removed, typing data is all removed
    func deleteTypingsAfterAccountDelete() {
        FirebaseReference(.Typing).document(User.currentId!).delete()
    }
    
}
