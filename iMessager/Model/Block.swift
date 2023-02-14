//
//  Block.swift
//  iMessager
//
//  Created by 高橋悟生 on 2023/02/08.
//

import Foundation
import FirebaseFirestoreSwift

struct Block: Codable {
    
    var id = ""
    var blockMemberIds = [""]
    @ServerTimestamp var date = Date()
    
}
