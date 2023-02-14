//
//  FirebaseUserListener.swift
//  iMessager
//
//  Created by 高橋悟生 on 2023/01/26.
//

import Foundation
import FirebaseAuth

class FirebaseUserListener {
    
    static let shared = FirebaseUserListener()
    
    private init() {}
    
    // MARK: - Login
    func loginUserWithEmail(email: String, password: String, completion: @escaping (_ error: Error?, _ isEmailVerified: Bool) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { (authDataResult, error) in
            
            if authDataResult?.user != nil {
                FirebaseUserListener.shared.downloadUserFromFirebase(userId: authDataResult!.user.uid, email: email)
                completion(error, true)
            } else {
                print("email is not verified")
                completion(error, false)
            }
            
        }
    }
    
    // MARK: - Register
    func registerUserWith(email: String, password: String, completion: @escaping (_ error: Error?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { (authDataResult, error) in
            
            completion(error)
            
            if error == nil {
                
                // send verification email
                authDataResult!.user.sendEmailVerification { (error) in
                    print("auth email sent with error: ")
                }
                
                // create user and save it
                if authDataResult?.user != nil {
                    let user = User(id: authDataResult!.user.uid, username: email, email: email, pushId: "", avatarLink: "", status: "オンライン", introduction: "")
                    
                    // locally save user
                    saveUserLocally(user)
                    // firestore save user
                    self.saveUserToFirestore(user)
                    
                }
            }
            
        }
    }
    
    // MARK: - Resend link methods
    func resendVerificationEmail(email: String, completion: @escaping (_ error: Error?) -> Void) {
        Auth.auth().currentUser?.reload(completion: { (error) in
            Auth.auth().currentUser?.sendEmailVerification(completion: { (error) in
                completion(error)
            })
        })
    }
    
    // MARK: - Reset Password methods
    func resetPasswordFor(email: String, completion: @escaping (_ error: Error?) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { (error) in
            completion(error)
        }
    }
    
    // MARK: - LogOut
    func logOutCurrentUser(completion: @escaping (_ error: Error?) -> Void) {
        do {
            try Auth.auth().signOut()
            
            // locally remove
            userDefaults.removeObject(forKey: kCURRENTUSER)
            userDefaults.synchronize()
            
            completion(nil)
        } catch let error as NSError {
            completion(error)
        }
    }
    
    
    // MARK: - Delete User Account
    func deleteUser(completion: @escaping (_ error: Error?) -> Void) {
        let userId = User.currentId
        
        Auth.auth().currentUser?.delete(completion: { (error) in
            if error != nil {
                completion(error)
            } else {
                
                //delete user from firestore
                if let deleteUserId = userId {
                    self.deleteUserInFirebase(deleteUserId)
                }
                
                completion(error)
                
            }
            
        })
    }
    
    
    
    
    
    // MARK: - Save users
    func saveUserToFirestore(_ user: User) {
        do {
            try FirebaseReference(.User).document(user.id).setData(from: user)
        } catch  {
            print(error.localizedDescription, "adding user error")
        }
    }
    
    // MARK: - Download
    func downloadUserFromFirebase(userId: String, email: String? = nil) {
        
        FirebaseReference(.User).document(userId).getDocument { (querySnapshot, error) in
            
            guard let document = querySnapshot else {
                print("no document for user")
                return
            }
            
            let result = Result {
                try? document.data(as: User.self)
            }
            
            switch result {
            case .success(let userObject):
                if let user = userObject {
                    saveUserLocally(user)
                } else {
                    print("Document does not exist")
                }
            case .failure(let error):
                print("Error decoding user", error)
            }
        }
    }
    
    
    // black list and blockList remove
    func downloadAllUsersFromFirebase(completion: @escaping (_ allUsers: [User]) -> Void) {
        
        // users who removed from black and blockList
        var users: [User] = []
        
        FirebaseReference(.User).limit(to: 500).getDocuments { (querySnapshot, error) in
            
            guard let document = querySnapshot?.documents else {
                print("no documents in all users")
                return
            }
            
            let allUsers = document.compactMap { (queryDocumentSnapshot) -> User? in
                return try? queryDocumentSnapshot.data(as: User.self)
            }
            
            for user in allUsers {
                if User.currentId != user.id && !user.black && !User.currentUser!.blockList.contains(user.id) {
                    users.append(user)
                }
            }
            
            completion(users)
        }
    }
    
    func downloadUsersFromFirebase(withIds: [String], completion: @escaping (_ allUsers: [User]) -> Void) {
        
        var count = 0
        var usersArray: [User] = []
        
        for userId in withIds {
            
            FirebaseReference(.User).document(userId).getDocument { (querySnapshot, error) in
                
                guard let document = querySnapshot else {
                    print("no document for user")
                    return
                }
                
                if let user = try? document.data(as: User.self) {
                    usersArray.append(user)
                    count += 1
                }
                
                if count == withIds.count {
                    completion(usersArray)
                }
            }
        }
    }
    
    func downloadBlockedUsersFromFirebase(completion: @escaping (_ allBlockedUsers: [User]) -> Void) {
        
        // blocked users
        var users: [User] = []
        
        FirebaseReference(.User).limit(to: 500).getDocuments { (querySnapshot, error) in
            
            guard let document = querySnapshot?.documents else {
                print("no documents in all users")
                return
            }
            
            let allUsers = document.compactMap { (queryDocumentSnapshot) -> User? in
                return try? queryDocumentSnapshot.data(as: User.self)
            }
            
            for user in allUsers {
                if User.currentId != user.id && !user.black && User.currentUser!.blockList.contains(user.id) {
                    print(user)
                    users.append(user)
                }
            }
            
            completion(users)
        }
    }
    
    
//    func downloadNonBlockedUsersFromFirebase(completion: @escaping (_ nonBlockedUsers: [User]?) -> Void) {
//
//        FirebaseBlockListener.shared.downloadIdentifyBlock(userId: User.currentId!) { block in
//
//            if block.blockMemberIds.count == 0 {
//                return
//            }
//
//            self.downloadAllUsersFromFirebase { allUsers in
//                var nonblockedMembers: [User] = []
//
//                for user in allUsers {
//                    if !block.blockMemberIds.contains(user.id) {
//                        nonblockedMembers.append(user)
//                    }
//                }
//
//                completion(nonblockedMembers)
//
//            }
//
//        }
//
//    }
//
//    func downloadBlockedUsersFromFirebase(completion: @escaping (_ blockedUsers: [User]?) -> Void) {
//
//        FirebaseBlockListener.shared.downloadIdentifyBlock(userId: User.currentId!) { block in
//
//            if block.blockMemberIds.count == 0 {
//                return
//            }
//
//            self.downloadUsersFromFirebase(withIds: block.blockMemberIds) { allUsers in
//                return completion(allUsers)
//            }
//
//        }
//
//    }
    
    
    // MARK: - checkExistUser
    func checkExistingUser(userId: String, completion: @escaping (_ exist: Bool) -> Void) {
        FirebaseReference(.User).document(userId).getDocument { (querySnapshot, error) in
            guard let document = querySnapshot else {
                print("no document for user")
                completion(false)
                return
            }
            
            completion(document.exists)
            
        }
    }
    
    // MARK: - check blocked(check receiverUser block senderUser)
    func checkBlockedSender(userId: String, completion: @escaping (_ isBlocked: Bool) -> Void) {
        FirebaseReference(.User).document(userId).getDocument { (querySnapshot, error) in
            guard let document = querySnapshot else {
                print("no document for user")
                completion(false)
                return
            }
            
            if let user = try? document.data(as: User.self) {
                return user.blockList.contains(User.currentId!) ? completion(true) : completion(false)
            }

        }
    }
    
    
    // MARK: - update User in firestore
    func updateUserInFirebase(_ user: User) {
        
        do {
            try FirebaseReference(.User).document(user.id).setData(from: user)
        } catch {
            print(error.localizedDescription, "updating user...")
        }
        
    }
    
    
    // MARK: - delete User on firestore
    func deleteUserInFirebase(_ userId: String) {
        FirebaseReference(.User).document(userId).delete()
    }
    
    
    
}
