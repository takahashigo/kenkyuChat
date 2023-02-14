//
//  FirebaseChannelRequestListener.swift
//  iMessager
//
//  Created by 高橋悟生 on 2023/02/03.
//

import Foundation
import FirebaseFirestore

class FirebaseChannelRequestListener {
    
    static let shared = FirebaseChannelRequestListener()
    
    var channelRequestListener: ListenerRegistration!
    
    private init() {}
    
    // MARK: - Fetching
    func downloadRequestChannelsFromFirebase(completion: @escaping (_ allChannelRequests: [ChannelRequest]) -> Void) {
        
        channelRequestListener = FirebaseReference(.ChannelRequest).whereField(kRECEIVERUSERID, isEqualTo: User.currentId!).addSnapshotListener({ (querySnapshot, error) in
            
            guard let documents = querySnapshot?.documents else {
                print("no documents for user channelRequests")
                return
            }
            
            var allChannelRequests = documents.compactMap { (queryDocumentSnapshot) -> ChannelRequest? in
                return try? queryDocumentSnapshot.data(as: ChannelRequest.self)
            }
            
            completion(allChannelRequests)
            
        })
    }
    
    func downloadIdentifyChannelRequests(channelId: String, requestUserId: String, completion: @escaping (_ channelRequests: [ChannelRequest]) -> Void) {

        FirebaseReference(.ChannelRequest).getDocuments { (querySnapshot, error) in

            guard let documents = querySnapshot?.documents else {
                print("no documents for all channelRequests")
                return
            }

            var allChannelRequests = documents.compactMap { (queryDocumentSnapshot) -> ChannelRequest? in
                return try? queryDocumentSnapshot.data(as: ChannelRequest.self)
            }
            
            var idetifyChannelRequests = allChannelRequests.filter { channelRequest in
                channelRequest.requestUserId == requestUserId && channelRequest.channelId == channelId
            }
            
            print(idetifyChannelRequests)

            completion(idetifyChannelRequests)

        }
    }
    
    
    // MARK: - Add and Delete
    func saveChannelRequest(_ channelRequest: ChannelRequest) {
        
        do {
            try FirebaseReference(.ChannelRequest).document(channelRequest.id).setData(from: channelRequest)
        } catch {
            print("Error saving channelRequest", error.localizedDescription)
        }
        
    }
    
    func deleteChannelRequest(_ channelRequest: ChannelRequest) {
        FirebaseReference(.ChannelRequest).document(channelRequest.id).delete()
    }
    
    
    // MARK: - remove listener
    func removeListeners() {
        self.channelRequestListener.remove()
    }
    
    // MARK: - delete channelRequests
    func deleteChannelRequestsAfterAccountDelete() {
        FirebaseReference(.ChannelRequest).whereField(kRECEIVERUSERID, isEqualTo: User.currentId!).getDocuments { (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
                print("no documents for user channelRequests")
                return
            }
            
            var allChannelRequests = documents.compactMap { (queryDocumentSnapshot) -> ChannelRequest? in
                return try? queryDocumentSnapshot.data(as: ChannelRequest.self)
            }
            
            for deleteChannelRequest in allChannelRequests {
                self.deleteChannelRequest(deleteChannelRequest)
            }
        }
        
        FirebaseReference(.ChannelRequest).whereField(kREQUESTUSERID, isEqualTo: User.currentId!).getDocuments { (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
                print("no documents for user channelRequests")
                return
            }
            
            var allChannelRequests = documents.compactMap { (queryDocumentSnapshot) -> ChannelRequest? in
                return try? queryDocumentSnapshot.data(as: ChannelRequest.self)
            }
            
            for deleteChannelRequest in allChannelRequests {
                self.deleteChannelRequest(deleteChannelRequest)
            }
        }
        
        
    }
    
    
    
    
    
}
