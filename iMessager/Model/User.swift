//
//  User.swift
//  iMessager
//
//  Created by 高橋悟生 on 2023/01/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestoreSwift

struct User: Codable, Equatable {
    var id = ""
    var username: String
    var email: String
    var pushId = ""
    var avatarLink = ""
    var status: String
    var introduction: String
    var black: Bool = false
    var blockList: [String] = []
    
    static var currentId: String? {
        return Auth.auth().currentUser?.uid
    }
    
    static var currentUser: User? {
        if Auth.auth().currentUser != nil {
            if let dictionary = UserDefaults.standard.data(forKey: kCURRENTUSER) {
                let decoder = JSONDecoder()
                
                do {
                    let userObject = try decoder.decode(User.self, from: dictionary)
                    
                    return userObject
                } catch {
                    print("Error decoding user from user defaults")
                }
            }
        }
        return nil
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
}


func saveUserLocally(_ user: User) {
    
    let encoder = JSONEncoder()
    
    do {
        let data = try encoder.encode(user)
        UserDefaults.standard.set(data, forKey: kCURRENTUSER)
    } catch {
        print("error saving user locally", error.localizedDescription)
    }
    
}


func createDummyUsers() {
    
    let names = ["けんじ", "さとう", "たんじ", "あけみ", "けん", "さくら"]
    var imageIndex = 1
    var userIndex = 1
    
    for i in 0..<5 {
        
        let id = UUID().uuidString
        let fileDirectory = "Avatar/" + "_\(id)" + ".jpg"
        
        FileStorage.uploadImage(UIImage(named: "user\(imageIndex)")!, directory: fileDirectory) { avatarLink in
            
            let user = User(id: id, username: names[i], email: "user\(userIndex)@email.com", pushId: "", avatarLink: avatarLink ?? "", status: "オンライン", introduction: "")
            
            userIndex += 1
            
            FirebaseUserListener.shared.saveUserToFirestore(user)
        }
        
        imageIndex += 1
        if imageIndex == 5 {
            imageIndex = 1
        }
        
        
    }
    
}
