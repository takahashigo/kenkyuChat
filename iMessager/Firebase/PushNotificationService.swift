//
//  PushNotificationService.swift
//  iMessager
//
//  Created by 高橋悟生 on 2023/02/02.
//

import Foundation

class PushNotificationService {
    
    static let shared = PushNotificationService()
    
    private init() {}
    
    func sendPushNotificationTo(userIds: [String], body: String, channel: Channel? = nil, chatRoomId: String) {
        
        FirebaseUserListener.shared.downloadUsersFromFirebase(withIds: userIds) { (users) in
            
            for user in users {
                
                let title = channel != nil ? channel!.name : User.currentUser?.username ?? "User"
                
                self.sendMessageToUser(to: user.pushId, title: title, body: body)
                
            }
            
        }
        
    }
    
    func sendChannelRequestPushNotificationTo(userId: String, title: String, body: String, channelRequest: ChannelRequest) {
        
        
        FirebaseUserListener.shared.downloadUsersFromFirebase(withIds: [userId]) { allUsers in
            
            for user in allUsers {
                
                let title = title
                
                self.sendMessageToUser(to: user.pushId, title: title, body: body)
                
            }
            
        }
        
    }
    
    
    private func sendMessageToUser(to token: String, title: String, body: String) {
        
        let urlString = "https://fcm.googleapis.com/fcm/send"
        
        let url = NSURL(string: urlString)!
        
        let paramString: [String: Any] = ["to": token,
                                          "notification": [
                                            "title": title,
                                            "body": body,
                                            "badge": "1",
                                            "sound": "default"
                                          ]
        ]
        
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: paramString, options: [.prettyPrinted])
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("key= \(kSERVERKEY)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request as URLRequest)
        task.resume()
        
        
    }
    
}
