//
//  Account.swift
//  Intern
//
//  Created by Ali on 18/03/21.
//

import Foundation
import Firebase
import SwiftUI
import UIKit
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
import FirebaseMessaging
import Combine

struct Audio {
    
}

class Account: UIViewController, ObservableObject {
    
    @Published var user = User()
    @Published var url: URL? = nil
    @Published var patients = [Patient]()
    @Published var error = false
    @Published var createdSuccessfully = false
    
    @Published private(set) var signedIn: Bool = true
    
    @Published var usernames: [String] = []
    @Published var conversations = [String:[String:String]]()
    @Published var messages: [Message2] = []
    @Published var results = [SearchResult]()
    var names: [String:String] = [:]
    //var names2: [[String:String]] = [:]
    
    var handle : AuthStateDidChangeListenerHandle?
   
    
    let uid = Auth.auth().currentUser?.uid ?? "uid"
    
    public var completion: ((SearchResult) -> (Void))?
    
    private var users = [[String: String]]()
    private var hasFetched = false
    
    @AppStorage("currentUsername") var currentUsername: String = ""
    @AppStorage("currentEmail") var currentEmail: String = ""
    
    let database = Firestore.firestore()
    let auth = Auth.auth()
    let ref = Storage.storage().reference()
    
    var conversationListener: ListenerRegistration?
    var userDataListener: ListenerRegistration?
    var chatListener: ListenerRegistration?
    var otherUsername = ""
    var newError = ""
    
    // MARK: -Intent(s)
    func removeProfilePhoto() {
        user.profileImageUrl = "null"
    }
    
    func addNewPatient(patient: Patient) {
        patients.append(patient)
    }
    
    func removePatient(id: String) {
        patients.remove(at: 0)
    }
    
    func removeConversation(id key: String) {
        conversations.removeValue(forKey: key)
    }
    
    func addUserDetails(sex: String, country: String, practice: String) {
        user.country = country
        user.sex = sex
        user.practice = practice
    }
    
}


// MARK: -Search
extension Account {
    
    func searchButtonClicked (searchText: String) {
        guard !searchText.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        
        //searchBar.resignFirstResponder()
        results.removeAll()
        // spinner.show(in: view)
        searchUsers(query: searchText)
    }
    
    func filterUsers(with term: String) {
        /// update the UI: either show results or show no results label
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String, hasFetched else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        
        // self.spinner.dismiss()
        
        let results: [SearchResult] = users.filter({
            guard let email = $0["email"], email != safeEmail else {
                return false
            }
            
            guard let name = $0["name"]?.lowercased() else {
                return false
            }
            
            return name.hasPrefix(term.lowercased())
        }).compactMap({
            
            guard let email = $0["email"],
                  let name = $0["name"] else {
                return nil
            }
            
            return SearchResult(name: name, email: email)
        })
        
        self.results = results
        
        // updateUI()
    }
    
    func searchUsers(query: String) {
        /// check if array has firebase results
        if hasFetched {
            /// if it does: filter
            filterUsers(with: query)
        }
        else {
            /// if not, fetch then filter
            DatabaseManager.shared.getAllUsers(completion: { [weak self] result in
                switch result {
                case .success(let usersCollection):
                    self?.hasFetched = true
                    self?.users = usersCollection
                    self?.filterUsers(with: query)
                case .failure(let error):
                    print("Failed to get usres: \(error)")
                }
            })
        }
    }
    
//    func publicUsersInformationFetcher() {
//        let firstName = userData["firstName"] as? String ?? "Null"
//        let lastName = userData["lastName"] as? String ?? "Null"
//        let phoneNumber = userData["phoneNumber"] as? String ?? "Null" //we need a function to fetch users public info to be sreached.
//
//    }
    
    
    func searchUsers(queryText: String, completion: @escaping ([String : String]) -> Void) {
        self.names = [:]
        database.collection("users").getDocuments { snapshot, error in
            
            guard let ids = snapshot?.documents.compactMap({ $0.documentID }),
                  error == nil
            else {
                completion([:])
                return
            }
            
            let group = DispatchGroup()
            
            for id in ids {
                group.enter()
                self.database
                    .collection("users")
                    .document(id).addSnapshotListener { querySnapshot, error in
                        guard let userData = querySnapshot?.data() else {
                            print("User Data Not Found!")
                            return
                        }
                        let userName = userData["username"] as? String ?? "Null" //we only are searching user names? I want to search firstnames and lastnames, phone numbers
                        
                        
                        if userName.lowercased().contains(queryText.lowercased()), userName != self.user.username {
                           
                            self.names[userName] = id
                        }
                        
                    }
                group.leave()
            }
            group.notify(queue: .main) {
                completion(self.names)
            }
        }
    }
}


// MARK: -Conversations
extension Account {
    
    func loadUser() {
        fetchUserData()
        getConversations()
    }
    
    func listen(){
        handle = Auth.auth().addStateDidChangeListener({ (auth, user) in
            if let user = user {
                print("User State Changed!")
                DispatchQueue.main.async {
                    self.user = User(uid: user.uid, email: user.email)
                }
                self.loadUser()
            } else {
                self.user = User()
            }
        })
    }
    
    func fetchUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        // Listen for user data
        userDataListener = database
            .collection("users")
            .document(uid).addSnapshotListener { querySnapshot, error in
                guard let userData = querySnapshot?.data() else {
                    print("User Data Not Found!")
                    return
                }
                
                self.user.name.title = userData["title"] as? String ?? "nil"
                self.user.name.first = userData["firstName"] as? String ?? "nil"
                self.user.name.last = userData["lastName"] as? String ?? "nil"
                self.user.email = userData["email"] as? String ?? "nil"
                self.user.profileImageUrl = userData["profileImageUrl"] as? String ?? "nil"
            }
    }
    
    func getConversations() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        // Listen for conversations
        conversationListener = database
            .collection("users")
            .document(uid)
            .collection("chats").addSnapshotListener { [weak self] snapshot, error in
                guard let ids = snapshot?.documents.compactMap({ $0.documentID }),
                      error == nil else {
                    return
                }
                let myGroup = DispatchGroup()
                for id in ids {
                    myGroup.enter()
                    self?.database
                        .collection("users")
                        .document(id).addSnapshotListener { querySnapshot, error in
                            guard let userData = querySnapshot?.data() else {
                                print("User Data Not Found!")
                                return
                            }
                            let username = userData["username"] as? String ?? "Null"
                            let firstName = userData["firstName"] as? String ?? "Null"
                            let email = userData["email"] as? String ?? "Null"
                            let token = userData["notificationToken"] as? String ?? "Null"
                            let profileImageUrl = userData["profileImageUrl"] as? String ?? "Null"
                            self?.conversations[id] = ["username": username, "firstName": firstName, "email": email, "url": profileImageUrl, "notificationToken": token]
                          
                        }
                    myGroup.leave()
                }
                myGroup.notify(queue: .main) {
    //                        let filtered = ids.filter({
    //                            $0.lowercased().hasPrefix(queryText.lowercased())
    //                        })
                   //self?.conversations = self!.names
                }
                
//                DispatchQueue.main.async {
//                    self?.conversations = self!.names
//                }
            }
    }
    
}


// MARK: -Get Chat / Send Messages
extension Account {
    
    func observeChat() {
        createConversation()
        guard let uid = Auth.auth().currentUser?.uid else { return }
        chatListener = database
            .collection("users")
            .document(uid)
            .collection("chats")
            .document(otherUsername)
            .collection("messages")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let objects = snapshot?.documents.compactMap({ $0.data() }),
                      error == nil else {
                    return
                }
                
                let messages: [Message2] = objects.compactMap({
                    guard let date = ISO8601DateFormatter().date(from: $0["created"] as? String ?? "") else {
                        return nil
                    }
                    return Message2(
                        text: $0["text"] as? String ?? "", 
                        type: $0["sender"] as? String == self?.currentUsername ? .sent : .received,
                        created: date
                    )
                }).sorted(by: { first, second in
                    return first.created < second.created
                })
                
                DispatchQueue.main.async {
                    self?.messages = messages
                }
            }
    }
    
    func sendMessage(text: String) {
        let newMessageId = UUID().uuidString
        let dateString = ISO8601DateFormatter().string(from: Date())
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard !dateString.isEmpty else {
            return
        }
        
        let data = [
            "text": text,
            "sender": currentUsername,
            "created": dateString
        ]
        
        database.collection("users")
            .document(uid)
            .collection("chats")
            .document(otherUsername)
            .collection("messages")
            .document(newMessageId)
            .setData(data)
        
        database.collection("users")
            .document(otherUsername)
            .collection("chats")
            .document(uid)
            .collection("messages")
            .document(newMessageId)
            .setData(data)
    }
    
    func sendVoiceMeesage(audio: Audio) {
        
    }
    
    func sendNotification () {
        
    }
    
    func getName(username: String, _ completion: @escaping (_ data: String?) -> Void ) {
        
        database.collection("users").document(username).getDocument { snapshot, error in
            guard let firstName = snapshot?.data()?["firstName"] as? String, error == nil else {
                completion(nil)
                return
            }
            completion(firstName)
        }
    }
    
    func createConversation() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        database.collection("users")
            .document(uid)
            .collection("chats")
            .document(otherUsername).setData(["created":"true"])
        
        database.collection("users")
            .document(otherUsername)
            .collection("chats")
            .document(uid).setData(["created":"true"])
    }
    
}

// MARK: -Profile
extension Account {

    func updateProfileImage() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let data = [
          
            "profileImageUrl": user.profileImageUrl,
        ]
        
        //-FireStore Database
        self.database
            .collection("users")
            .document(uid)
            .updateData(data as [String : Any]) { error in
                guard error == nil else {
                    return
                }
                
            }
    }
    
}

// MARK: -Auth
extension Account {
    
    func signIn(username: String, password: String) {
        let email = username
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
       // guard let uid = Auth.auth().currentUser?.uid else { return }
        ///username sign in
        // Get email from DB
        // Try to sign in
        self.auth.signIn(withEmail: email, password: password, completion: { [self] result, error in
            guard error == nil, result != nil else {
                return
            }
           
            print("signed in successfully")

            DispatchQueue.main.async {
                
                loadUser()
                self.signedIn = true
                self.currentEmail = email
                self.currentUsername = username
                
            }
        })
//        
//        database.collection("users").document(uid).getDocument { [weak self] snapshot, error in
//            guard let email = snapshot?.data()?["email"] as? String, error == nil else {
//                return
//            }
//            
//            
//            
//        }
        
        ///email sign in
        
        
        
        // Firebase Log In
//        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password, completion: { authResult, error in
            
//            guard let result = authResult, error == nil else {
//                print("Failed to log in user with email: \(email)")
//                //self.throwError(error: error?.localizedDescription ?? "Unknown Error!")
//                return
//            }
            
            //let user = result.user
//            print("signed in successfully")
//
//        })
        
        func getData() {
            DatabaseManager.shared.getDataFor(path: safeEmail, completion: { result in
                switch result {
                case .success(let data):
                    guard let userData = data as? [String: Any]
//                          let title = userData["title"] as? String,
//                          let firstName = userData["first_name"] as? String,
//                          let lastName = userData["last_name"] as? String,
                    else {
                        return
                    }
                case .failure(let error):
                    print("Failed to read data with error: \(error)")
                }
            })
        }
    }
    
    func signOut() {
        do {
            try auth.signOut()
            self.user = User()
            self.signedIn = false
        }
        catch {
            print(error)
        }
    }
    
    func signUp(email: String, password: String, handler: @escaping AuthDataResultCallback) {
        //-Create Account
        auth.createUser(withEmail: email, password: password, completion: handler)
    }
    
    func createUser(name: Name, username: String, email: String, phoneNumber: String, password: String, photo: UIImage?, id: String) {
        user.uid = id
        user.name = name
        user.email = email
        user.username = username
        user.phoneNumber = phoneNumber
        user.password = password
        user.photo = photo
    
        Messaging.messaging().token { token, error in
          if let error = error {
            print("Error fetching FCM registration token: \(error)")
          } else if let token = token {
            self.user.token = token
            print("FCM registration token: \(token)")
            print("Remote FCM registration token: \(token)")
          }
        }
        
        //-Upload profile image into storage
        uplaodImage(photo!) { url in
            self.user.profileImageUrl = url
            //-Insert user data into database
            self.insertUser(user: self.user)
        }
        
       
    }
    
    /// Uploads picture to firebase storage and returns completion with URL String to download
    func uplaodImage(_ profileImage : UIImage, completion : @escaping (String?)->()){
        print("IMAGE UPLAOD")
        let ref = Storage.storage().reference()
        let storageRef = ref.child("profile_images").child("\(uid).jpg")
        
        if let uploadData = profileImage.jpegData(compressionQuality: 0.2){    /// convert image to data
            storageRef.putData(uploadData, metadata: nil) { (metadata, error) in
                if let error = error {
                    completion(nil)
                    print(error.localizedDescription)
                } else {
                    storageRef.downloadURL { (url, error) in    /// get url from storage
                        if let error = error {
                            completion(nil)
                            print(error.localizedDescription)
                        } else {
                            completion(url?.absoluteString ?? "inavlid")
                        }
                    }
                }
            }
        }
    }
    
    func uplaodAudio(_ audio: Recording, completion : @escaping (String?)->()){
        print("Voice UPLAOD")
        let ref = Storage.storage().reference()
        let storageRef = ref.child("voice_messages").child("\(uid).m4a")
        
//        if let uploadData = audio {    /// convert image to data
//
//            storageRef.putData(uploadData, metadata: nil) { (metadata, error) in
//                if let error = error {
//                    completion(nil)
//                    print(error.localizedDescription)
//                } else {
//                    storageRef.downloadURL { (url, error) in    /// get url from storage
//                        if let error = error {
//                            completion(nil)
//                            print(error.localizedDescription)
//                        } else {
//                            completion(url?.absoluteString ?? "inavlid")
//                        }
//                    }
//                }
//            }
//        }
//    }
    
    // File located on disk
    // Create a reference to the file you want to upload
//    let audioFileRef = storageRef.child("audioFiles/audioFile.m4a") //adjust this to have a unique name

//    let uploadTask = audioFileRef.putFile(from: localAudioURL, metadata: nil) { metadata, error in
//      guard let metadata = metadata else {
//        // Uh-oh, an error occurred!
//        return
//      }
      //optionally, delete original local file here
    }
    
    func insertUser(user: User) {
        
        let data = [
            "email": user.email,
            "username": user.username,
            "title": user.name.title,
            "firstName": user.name.first,
            "lastName": user.name.last,
            "profileImageUrl": user.profileImageUrl,
            "notificationToken": user.token,
        ]
        
        //-FireStore Database
        self.database
            .collection("users")
            .document(user.uid!)
            .setData(data as [String : Any]) { error in
                guard error == nil else {
                    return
                }
                
                DispatchQueue.main.async {
                    self.signedIn = true
                }
            }
        
        //-Realtime Database
        //        DatabaseManager.shared.insertUser(with: user, completion: {  success in
        //
        //            if success && user.photo != nil {
        //                // Upload Image
        //                print("Uploading User Photo...")
        //                guard
        //                    let data = user.photo!.pngData() else {
        //                    return
        //                }
        //
        //                let filename = user.profilePictureFileName
        //                StorageManager.shared.uploadProfilePicture(with: data, fileName: filename, completion: { result in
        //                    switch result {
        //                    case .success(let downloadUrl):
        //                        UserDefaults.standard.setValue(downloadUrl, forKey: "url")
        //
        //                    case .failure(let error):
        //                        print("Storage manager error: \(error)")
        //                    }
        //                })
        //            }
        //        })
        
    }
    
    func validateAuth () {
        if auth.currentUser == nil {
           signedIn = false
           return
        } else {
            loadUser()
        }
        
    }

}
