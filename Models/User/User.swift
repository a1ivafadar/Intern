//
//  User.swift
//  Lego
//
//  Created by Ali on 13/03/21.
//
 
import Firebase
import UIKit

struct User: Identifiable {
    
    var name = Name()
    var email: String? = ""
    var phoneNumber = ""
    var password = ""
    var username = ""
    var specialty: String = ""
    var practice: String = ""
    var credits: String = "0"
    var rank: String = ""
    var sex: String = ""
    var country: String = ""
    var type: String = ""
    var userID: String = ""
    var token: String? = ""
    var id: String = ""
    var uid : String?
    
    var verified = false
    
    var profileImageUrl: String?
    var photo = UIImage(systemName: "person.circle")
    var profilePictureFileName = ""
    var patients : Array<Patient> = []
    
    init(uid:String, email:String?){
        self.uid = uid
        self.email = email
    }
    
    init() {
        
    }
    
    mutating func addNewPatient(patient: Patient) {
        self.patients.append(patient)
       // save patients to database
    }
    
    func safeEmail() -> String {
        var safeEmail = email!.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }

}



