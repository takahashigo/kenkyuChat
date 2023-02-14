//
//  ChannelRequest.swift
//  iMessager
//
//  Created by 高橋悟生 on 2023/02/03.
//

import Foundation
import FirebaseFirestoreSwift

struct ChannelRequest: Codable {
    
    var id = ""
    var channelId = ""
    var channelName = ""
    var receiveUserId = ""
    var receiveUsername = ""
    var requestUserId = ""
    var requestUsername = ""
    @ServerTimestamp var date = Date()
}
