//
//  IncomimgMessage.swift
//  iMessager
//
//  Created by 高橋悟生 on 2023/01/29.
//

import Foundation
import MessageKit
import CoreLocation


class IncomingMessage {
    
    var messageCollectionView: MessagesViewController
    
    init(_ collectionView: MessagesViewController) {
        messageCollectionView = collectionView
    }
    
    // MARK: - CreateMessage
    func createMessage(localMessage: LocalMessage) -> MKMessage? {
        
        let mkMessage = MKMessage(message: localMessage)
        
        // multimedia messages
        if localMessage.type == kPHOTO {
            let photoItem = PhotoMessage(path: localMessage.pictureUrl)
            mkMessage.photoItem = photoItem
            mkMessage.kind = MessageKind.photo(photoItem)
            
            FileStorage.downloadImage(imageUrl: localMessage.pictureUrl) { (image) in
                
                mkMessage.photoItem?.image = image
                self.messageCollectionView.messagesCollectionView.reloadData()
                
            }
        }
        
        if localMessage.type == kVIDEO {
            
            FileStorage.downloadImage(imageUrl: localMessage.pictureUrl) { (thumbNail) in
                FileStorage.downloadVideo(videoLink: localMessage.videoUrl) { (readyToPlay, fileName) in
                    
                    let videoURL = URL(fileURLWithPath: fileInDocumentsDirectory(fileName: fileName))
                    let videoItem = VideoMessage(url: videoURL)
                    
                    mkMessage.videoItem = videoItem
                    mkMessage.kind = MessageKind.video(videoItem)
                    
                }
                
                mkMessage.videoItem?.image = thumbNail
                self.messageCollectionView.messagesCollectionView.reloadData()
            }
        }
        
        if localMessage.type == kLOCATION {
            
            let locationItem = LocationMessage(location: CLLocation(latitude: localMessage.latitude, longitude: localMessage.longitude))
            mkMessage.kind = MessageKind.location(locationItem)
            mkMessage.locationItem = locationItem
            
        }
        
        if localMessage.type == kAUDIO {
            
            let audioMessage = AudioMessage(duration: Float(localMessage.audioDuration))
            mkMessage.kind = MessageKind.audio(audioMessage)
            mkMessage.audioItem = audioMessage
            
            FileStorage.downloadAudio(audioLink: localMessage.audioUrl) { (fileName) in
                
                let audioUrl = URL(fileURLWithPath: fileInDocumentsDirectory(fileName: fileName))
                mkMessage.audioItem?.url = audioUrl
                
            }
            self.messageCollectionView.messagesCollectionView.reloadData()
            
        }
        
        
        return mkMessage
    }
    
}
