//
//  Doctor.swift
//  Intern
//
//  Created by Ali on 08/03/21.
//

import Foundation

struct Doctor {
    
    var name: String
    var verified: Bool
    var specialty: String
    var rank: Rank
    var credits: Int
    
    mutating func addPatient(patient: Patient, folder: [Folder]) {
        
//        folder.append(patient)
        print("Patient \(patient.id) Added.")
    }
    
}

struct Rank {
    var insignia: String
}
