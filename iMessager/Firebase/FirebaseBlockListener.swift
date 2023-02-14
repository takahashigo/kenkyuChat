//
//  FirebaseBlockListener.swift
//  iMessager
//
//  Created by 高橋悟生 on 2023/02/08.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

class FirebaseBlockListener {
    
    static let shared = FirebaseBlockListener()
    
    var blockListener: ListenerRegistration!
    
    private init() {}
    
    // MARK: - Fetching
    // my block
    func downloadMyBlock(completion: @escaping (_ block: Block) -> Void) {

        blockListener = FirebaseReference(.Block).document(User.currentId!).addSnapshotListener({ (snapshot, error) in

            guard let snapshot = snapshot else { return }
            
            if snapshot.exists {
                
                guard let data = try? snapshot.data(as: Block.self) else {
                        print("Document data was empty.")
                        return
                      }

                completion(data)
                
            }
            
            

        })

    }
    
    
    // 特定のもの
    func downloadIdentifyBlock(userId: String, completion: @escaping (_ block: Block) -> Void) {

        FirebaseReference(.Block).getDocuments { (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
                print("no documents for all blocks")
                return
            }
            
            var allBlocks = documents.compactMap { (queryDocumentSnapshot) -> Block? in
                return try? queryDocumentSnapshot.data(as: Block.self)
            }
            
            var identifyBlock = allBlocks.filter { block in
                block.id == userId
            }[0]
            
            completion(identifyBlock)
            
        }
        
    }
    
    // MARK: - Add Delete
    func saveBlock(_ block: Block) {
        // add member, or remove member from memberIds
        do {
            try FirebaseReference(.Block).document(block.id).setData(from: block)
        } catch {
            print("Error saving block ", error.localizedDescription)
        }
        
    }
    
    func deleteBlock(_ block: Block) {
        FirebaseReference(.Block).document(block.id).delete()
    }
    
    
    
    
    
    
    
    
}
