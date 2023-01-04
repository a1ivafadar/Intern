//
//  AppStateModel.swift
//  Intern
//
//  Created by Ali on 24/04/21.
//

import Foundation
import Firebase
import SwiftUI
import UIKit
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
import Combine

class AppStateModel {
    
//    func pictureUrl() {
//
//        let safeEmail = DatabaseManager.safeEmail(emailAddress: user.email!)
//        let filename = safeEmail + "_profile_picture.png"
//        let path = "images/"+filename
//        //var Url : URL? = nil
//        StorageManager.shared.downloadURL(for: path, completion: { result in
//            switch result {
//            case .success(let url):
//                self.user.url(url: url)
//                self.url = self.user.url
//            case .failure(let error):
//                print("Failed to get download url: \(error)")
//            }
//        })
//
//    }
    
//    func throwError(error: String) {
//        self.error = true
//        newError = error
//    }

    init() {
        //self.showingSignIn = Auth.auth().currentUser == nil
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


//MARK:- Send Message to firebase
    
    func sendData(user: User, message : String, imageUrl : String? = nil){
        let reference = ref.child("messages")

        let childRef = reference.childByAutoId()

        let toId = user.id

        let fromId = Auth.auth().currentUser!.uid

        let timeStamp = Int(NSDate().timeIntervalSince1970)

        var values = ["text":message, "toId":toId, "fromId":fromId,"timestamp":timeStamp] as [String : Any]

        if let imageUrl = imageUrl { values["imageUrl"] = imageUrl }

        childRef.updateChildValues(values) { (error, ref) in

            if let error = error{

                print(error.localizedDescription)

            }else{

                let userMessagesRef = Database.database().reference().child("user-messages").child(fromId)

                let messageId = childRef.key!

                userMessagesRef.updateChildValues([messageId:"a"])

                let recipientUserMessagesReference = Database.database().reference().child("user-messages").child(toId ?? "")

                recipientUserMessagesReference.updateChildValues([messageId:"a"])
            }
        }
    }

//MARK:- Update profile picture
    func updateProfileImage(url: String) {
        let ref = self.ref.child("users").child(session?.uid ?? "uid")
        ref.updateChildValues(["imageUrl":url])
    }

    func createProfile(_ profileImage : UIImage){
        uplaodImage(profileImage) { (url) in
            if let url = url {
                self.updateProfileImage(url: url)
            }
        }
    }

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
                        }else{
                            completion(url?.absoluteString ?? "inavlid")
                        }
                    }
                }
            }
        }
    }

    let ref = Database.database().reference()

    var didChange = PassthroughSubject<Account,Never>()

    let uid = Auth.auth().currentUser?.uid ?? "uid"

    @Published var session : User? {
        didSet {
            //self.didChange.send(self)
        }
    }

    @Published var users2 = [User]()
    @Published var messagez = [Msg]()
    @Published var messagesDictionary = [String: Msg]()

    var handle : AuthStateDidChangeListenerHandle?

    func listen(){
        handle = Auth.auth().addStateDidChangeListener({ (auth, user) in
            if let user = user {
                print("user state changed")
                self.session = User(uid: user.uid, email: user.email)
                self.fetchUsers()
                self.observeUserMessages()
            } else {
                self.session = nil
            }
        })
    }

    func signUp(email:String,password:String, handler : @escaping AuthDataResultCallback){
        Auth.auth().createUser(withEmail: email, password: password, completion: handler)
    }

    func signIn(email:String,password:String,handler : @escaping AuthDataResultCallback){
        Auth.auth().signIn(withEmail: email, password: password, completion: handler)
    }

    func signOut(){
        do {
            try Auth.auth().signOut()
            self.session = nil
            //self.users = []
            self.messagez = [Msg]()
            self.messagesDictionary = [String: Msg]()
        } catch {
            print("Error signing out")
        }
    }

    func unbind(){
        if let handle = handle {
            print("unbind")
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    deinit {
        unbind()
    }

    func observeUserMessages(){

        guard let uid = Auth.auth().currentUser?.uid else { return }

        let reference = self.ref.child("user-messages").child(uid)

        reference.observe(.childAdded, with: { (snapshot) in

            let messageId = snapshot.key

            let messagesReference = Database.database().reference().child("messages").child(messageId)

            messagesReference.observeSingleEvent(of: .value, with: { (snapshot) in

                if let dictionary = snapshot.value as? [String:AnyObject]{

                    var message = Msg()

                    if let text = dictionary["text"]{ message.text = text  as? String }
                    if let imageUrl = dictionary["imageUrl"]{ message.imageUrl = imageUrl  as? String }
                    message.fromId = (dictionary["fromId"] as! String)
                    message.toId = (dictionary["toId"] as! String)
                    message.timestamp = (dictionary["timestamp"] as! Int)

                    if let chatPatnerId = message.chatPatnerId() {

                        self.messagesDictionary[chatPatnerId]  = message

                        self.messagez = Array(self.messagesDictionary.values)

                        //MARK:- Sort messages Array
                        self.messagez.sort { (message1, message2) -> Bool in
                            var bool = false
                            if let time1 = message1.timestamp, let time2 = message2.timestamp {
                                bool = time1 > time2
                            }
                            return bool
                        }
                    }
                }
            }, withCancel: nil)
        }, withCancel: nil)
    }

    func observeMessages(completion : @escaping ([String:AnyObject],String)->()){
        guard let uid = Auth.auth().currentUser?.uid else {return}

        let userMessagesref = ref.child("user-messages").child(uid)

        userMessagesref.observe(.childAdded, with: { (snapshot) in

            let messageId = snapshot.key

            let messagesRef = Database.database().reference().child("messages").child(messageId)

            messagesRef.observeSingleEvent(of: .value, with: { (snapshot) in

                guard let dictionary = snapshot.value as?[String:AnyObject] else { return }

                completion(dictionary,snapshot.key)
            }, withCancel: nil)
        }, withCancel: nil)
    }

    func fetchUsers(){
        ref.child("users").observe(.childAdded, with: { (snapshot) in
            if let dictionary = snapshot.value as? [String: AnyObject] {
                var user = User()
                //user.fullName = (dictionary["name"] as! String)
                user.email = (dictionary["email"] as! String)
                // user.profileImageUrl = (dictionary["profileImageUrl"] as! String)
                user.id = snapshot.key
                self.users2.append(user)
            }
        }, withCancel: nil)
    }

    func createUser(user: User){
        let param = ["name":user.name.full,"email":user.email,"profileImageUrl":user.profileImageUrl]
        ref.child("users").child(getUID()).setValue(param) { (error, ref) in
            if let error = error{
                print(error)
            }
        }
    }

    func getUserFromMessage(_ message : Msg,completion: @escaping (User)->()){
        guard let chatPatnerId = message.chatPatnerId() else { return }


        ref.child("users").child(chatPatnerId).observe(.value) { (snapshot) in
            guard let dictionary = snapshot.value as? [String:AnyObject]  else { return}

            var user = User()

            //user.fullName = (dictionary["name"] as! String)
            user.email = (dictionary["email"] as! String)
            user.profileImageUrl = (dictionary["profileImageUrl"] as! String)
            user.id = chatPatnerId

            completion(user)
        }
    }

    func getUserFromMSG(_ message : Msg) -> User {

        if let chatPatnerId = message.chatPatnerId(){

            let user =  self.users2.filter { $0.id == chatPatnerId }

            return user.first!
        }
        return User()
    }


    func createAccount1(user: User)  {

        // Firebase User
        FirebaseAuth.Auth.auth().createUser(withEmail: user.email!, password: user.password, completion: { authResult, error in

            print("Creating user with email: \(user.email ?? "No Email")")

            guard authResult != nil, error == nil else {
                print("Error creating user: \(error.debugDescription)")
                return
            }

            DatabaseManager.shared.insertUser(with: user, completion: {  success in
                print("Inserting User: \(user.email ?? user.phoneNumber)")

                //self.register()

                if success && user.photo != nil {
                    // Upload Image
                    print("Uploading User Photo...")
                    guard
                        let data = user.photo!.pngData() else {
                        return
                    }

                    let filename = user.profilePictureFileName
                    StorageManager.shared.uploadProfilePicture(with: data, fileName: filename, completion: { result in
                        switch result {
                        case .success(let downloadUrl):
                            UserDefaults.standard.setValue(downloadUrl, forKey: "url")

                        case .failure(let error):
                            print("Storage manager error: \(error)")
                        }
                    })
                }
            })
        })
    }
    
}
