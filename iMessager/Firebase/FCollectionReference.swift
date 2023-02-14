//
//  FCollectionReference.swift
//  iMessager
//
//  Created by 高橋悟生 on 2023/01/26.
//

import Foundation
import FirebaseFirestore

enum FCollectionReference: String {
    case User
    case Recent
    case Messages
    case Typing
    case Channel
    case ChannelRequest
    case Block
}

func FirebaseReference(_ collectionReference: FCollectionReference) -> CollectionReference {
    
    return Firestore.firestore().collection(collectionReference.rawValue)
}
