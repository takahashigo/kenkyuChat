//
//  GlobalFunctions.swift
//  iMessager
//
//  Created by 高橋悟生 on 2023/01/27.
//

import Foundation
import UIKit
import AVFoundation

func fileNameFrom(fileUrl: String) -> String {
    let name = ((fileUrl.components(separatedBy: "_").last)?.components(separatedBy: "?").first!)?.components(separatedBy: ".").first!
    return name!
}


func timeElapsed(_ date: Date) -> String {
    
    let seconds = Date().timeIntervalSince(date)
    
    var elapsed = ""
    
    if seconds < 60 {
        elapsed = "今"
    } else if seconds < 60 * 60 {
        let minutes = Int(seconds / 60)
//        let minText = minutes > 1 ? "mins" : "min"
        let minText = "分前"
        elapsed = "\(minutes) \(minText)"
    } else if seconds < 24 * 60 * 60 {
        let hours = Int(seconds / (60 * 60))
//        let hourText = hours > 1 ? "hours" : "hour"
        let hourText = "時間前"
        elapsed = "\(hours) \(hourText)"
    } else {
        elapsed = date.longDate()
    }
    
    return elapsed
}


func videoThumbnail(video: URL) -> UIImage {
    
    let asset = AVURLAsset(url: video, options: nil)
    
    let imageGenerator = AVAssetImageGenerator(asset: asset)
    imageGenerator.appliesPreferredTrackTransform = true
    
    let time = CMTimeMakeWithSeconds(0.5, preferredTimescale: 1000)
    var actualTime = CMTime.zero
    
    var image: CGImage?
    
    do {
        image = try imageGenerator.copyCGImage(at: time, actualTime: &actualTime)
    } catch let error as NSError {
        print("error making thumbnail", error.localizedDescription)
    }
    
    if image != nil {
        return UIImage(cgImage: image!)
    } else {
        return UIImage(named: "photoPlaceholder")!
    }
    
    
}


func removeCurrentUserFrom(userIds: [String]) -> [String] {
    
    var allIds = userIds
    
    for id in allIds {
        
        if id == User.currentId {
            allIds.remove(at: allIds.firstIndex(of: id)!)
        }
        
    }
    
    return allIds
}



