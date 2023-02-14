//
//  RealmManager.swift
//  iMessager
//
//  Created by 高橋悟生 on 2023/01/29.
//

import Foundation
import RealmSwift

class RealmManager {
    
    static let shared = RealmManager()
    let realm = try! Realm()
    
    private init() {}
    
    func saveToRealm<T: Object>(_ object: T) {
        
        do {
            try realm.write {
                realm.add(object, update: .modified)
            }
        } catch {
            print("Error saving realm Object", error.localizedDescription)
        }
        
    }
    
    func saveHideMemberIdsToRealm<T: Object>(_ object: T) {
        
        do {
            try realm.write {
                realm.add(object, update: .modified)
            }
        } catch {
            print("Error saving realm Object", error.localizedDescription)
        }
        
    }
    
}
