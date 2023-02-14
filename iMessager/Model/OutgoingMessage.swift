//
//  OutgoingMessage.swift
//  iMessager
//
//  Created by 高橋悟生 on 2023/01/29.
//

import Foundation
import UIKit
import FirebaseFirestoreSwift
import Gallery

class OutgoingMessage {
    
    var isBlocked: Bool?
    
    class func send(chatId: String, text: String?, photo: UIImage?, video: Video?, audio: String?, audioDuration: Float = 0.0, location: String?, memberIds: [String], receiverUserId: String?) {
        let currentUser = User.currentUser!
        
        let message = LocalMessage()
        message.id = UUID().uuidString
        message.chatRoomId = chatId
        message.senderId = currentUser.id
        message.senderName = currentUser.username
        message.senderInitials = String(currentUser.username.first!)
        message.date = Date()
        message.status = kSENT
        
        
//        // check blocked
//        if let receiverId = receiverUserId {
//            FirebaseUserListener.shared.checkBlockedSender(userId: receiverId) { isBlocked in
//                if isBlocked {
//                    message.hideMemberIds.append(receiverId)
//                }
//            }
//        }
        

        if text != nil {
            //send text message
            sendTextMessage(message: message, text: text!, memberIds: memberIds)
        }
        
        if photo != nil {
            //send photo message
            sendPictureMessage(message: message, photo: photo!, memberIds: memberIds)
        }
        
        if video != nil {
            //send video massage
            sendVideoMessage(message: message, video: video!, memberIds: memberIds)
        }
        
        if location != nil {
            // send location message
            sendLocationMessage(message: message, memberIds: memberIds)
        }
        
        if audio != nil {
            // send audio message
            sendAudioMessage(message: message, audioFileName: audio!, audioDuration: audioDuration, memberIds: memberIds)
        }
        
        
        //Send push notification
        PushNotificationService.shared.sendPushNotificationTo(userIds: removeCurrentUserFrom(userIds: memberIds), body: message.message, chatRoomId: chatId)
        
        
        // Update recent
        FirebaseRecentListener.shared.updateRecents(chatRoomId: chatId, lastMessage: message.message)
        
    }
    
    
    class func sendChannel(channel: Channel, text: String?, photo: UIImage?, video: Video?, audio: String?, audioDuration: Float = 0.0, location: String?) {
        let currentUser = User.currentUser!
        var channel = channel
        
        let message = LocalMessage()
        message.id = UUID().uuidString
        message.chatRoomId = channel.id
        message.senderId = currentUser.id
        message.senderName = currentUser.username
        message.senderInitials = String(currentUser.username.first!)
        message.date = Date()
        message.status = kSENT
        
        if text != nil {
            //send text message
            sendTextMessage(message: message, text: text!, memberIds: channel.memberIds, channel: channel)
        }
        
        if photo != nil {
            //send photo message
            sendPictureMessage(message: message, photo: photo!, memberIds: channel.memberIds, channel: channel)
        }
        
        if video != nil {
            //send video massage
            sendVideoMessage(message: message, video: video!, memberIds: channel.memberIds, channel: channel)
        }
        
        if location != nil {
            // send location message
            sendLocationMessage(message: message, memberIds: channel.memberIds, channel: channel)
        }
        
        if audio != nil {
            // send audio message
            sendAudioMessage(message: message, audioFileName: audio!, audioDuration: audioDuration, memberIds: channel.memberIds, channel: channel)
        }
        
        
        //Send push notification
        PushNotificationService.shared.sendPushNotificationTo(userIds: removeCurrentUserFrom(userIds: channel.memberIds), body: message.message, channel: channel, chatRoomId: channel.id)
        
    
        channel.lastMessageDate = Date()
//        FirebaseRecentListener.shared.updateRecents(chatRoomId: channel.id, lastMessage: message.message)
        FirebaseChannelListener.shared.saveChannel(channel)
        
    }
    
    
    class func sendMessage(message: LocalMessage, memberIds: [String]) {
        
        // locally Realm save
        RealmManager.shared.saveToRealm(message)
        
        for memberId in memberIds {
            // firestore save
            FirebaseMessageListener.shared.saveMessage(message, memberId: memberId)
        }
        
    }
    
    
    class func sendChannelMessage(message: LocalMessage, channel: Channel) {
        
        // locally Realm save
        RealmManager.shared.saveToRealm(message)
        
        // firestore save
        FirebaseMessageListener.shared.saveChannelMessage(message, channel: channel)
        
        
    }
    
    
}


func sendTextMessage(message: LocalMessage, text: String, memberIds: [String], channel: Channel? = nil) {
    message.message = text
    message.type = kTEXT
    
    if channel != nil {
        // save for channel
        OutgoingMessage.sendChannelMessage(message: message, channel: channel!)
    } else {
        // save for chatRoom
        OutgoingMessage.sendMessage(message: message, memberIds: memberIds)
    }

}


func sendPictureMessage(message: LocalMessage, photo: UIImage, memberIds: [String], channel: Channel? = nil)  {
    message.message = "画像を送信しました"
    message.type = kPHOTO
    
    let fileName = Date().stringDate()
    let fileDirectory = "MediaMessages/Photo/" + "\(message.chatRoomId)/" + "_\(fileName)" + ".jpg"
    
    // save locally
    FileStorage.saveFileLocally(fileData: photo.jpegData(compressionQuality: 0.6)! as NSData, fileName: fileName)
    
    // upload
    FileStorage.uploadImage(photo, directory: fileDirectory) { (imageURL) in
        
        if imageURL != nil {
            
            message.pictureUrl = imageURL!
            
            if channel != nil {
                // save for channel
                OutgoingMessage.sendChannelMessage(message: message, channel: channel!)
            } else {
                // save for chatRoom
                OutgoingMessage.sendMessage(message: message, memberIds: memberIds)
            }

        }
    }
}


func sendVideoMessage(message: LocalMessage, video: Video, memberIds: [String], channel: Channel? = nil) {
    message.message = "動画を送信しました"
    message.type = kVIDEO
    
    let fileName = Date().stringDate()
    let thumbnailDirectory = "MediaMessages/Photo/" + "\(message.chatRoomId)/" + "_\(fileName)" + ".jpg"
    let videoDirectory = "MediaMessages/Video/" + "\(message.chatRoomId)/" + "_\(fileName)" + ".mov"
    
    let editor = VideoEditor()
    
    editor.process(video: video) { (processedVideo, videoUrl) in
        
        if let tempPath = videoUrl {
            
            let thumbnail = videoThumbnail(video: tempPath)
            
            FileStorage.saveFileLocally(fileData: thumbnail.jpegData(compressionQuality: 0.7)! as NSData, fileName: fileName)
            FileStorage.uploadImage(thumbnail, directory: thumbnailDirectory) { (imageLink) in
                
                if imageLink != nil {
                    
                    let videoData = NSData(contentsOfFile: tempPath.path)
                    
                    FileStorage.saveFileLocally(fileData: videoData!, fileName: fileName + ".mov")
                    FileStorage.uploadVideo(videoData!, directory: videoDirectory) { (videoLink) in
                        message.pictureUrl = imageLink ?? ""
                        message.videoUrl = videoLink ?? ""
                        
                        if channel != nil {
                            // save for channel
                            OutgoingMessage.sendChannelMessage(message: message, channel: channel!)
                        } else {
                            // save for chatRoom
                            OutgoingMessage.sendMessage(message: message, memberIds: memberIds)
                        }

                    }
                    
                }
                
            }
            
        }
        
    }
    
}

func sendLocationMessage(message: LocalMessage, memberIds: [String], channel: Channel? = nil) {
    
    let currentLocation = LocationManager.shared.currentLocation
    message.message = "位置情報を送信しました"
    message.type = kLOCATION
    message.latitude = currentLocation?.latitude ?? 0.0
    message.longitude = currentLocation?.longitude ?? 0.0
    
    if channel != nil {
        // save for channel
        OutgoingMessage.sendChannelMessage(message: message, channel: channel!)
    } else {
        // save for chatRoom
        OutgoingMessage.sendMessage(message: message, memberIds: memberIds)
    }

}

func sendAudioMessage(message: LocalMessage, audioFileName: String, audioDuration: Float, memberIds: [String], channel: Channel? = nil) {
    
    message.message = "ボイスメッセージを送信しました"
    message.type = kAUDIO
    
    let fileDirectory = "MediaMessages/Audio/" + "\(message.chatRoomId)/" + "_\(audioFileName)" + ".m4a"
    
    FileStorage.uploadAudio(audioFileName, directory: fileDirectory) { (audioUrl) in
        
        if audioUrl != nil {
            
            message.audioUrl = audioUrl ?? ""
            message.audioDuration = Double(audioDuration)
            
            if channel != nil {
                // save for channel
                OutgoingMessage.sendChannelMessage(message: message, channel: channel!)
            } else {
                // save for chatRoom
                OutgoingMessage.sendMessage(message: message, memberIds: memberIds)
            }

            
        }
        
    }
    
}
