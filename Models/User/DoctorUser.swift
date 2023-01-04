//
//  DoctorUser.swift
//  Intern
//
//  Created by Ali on 17/03/21.
//

import SwiftUI

class DoctorUser
{
    
    var id: String = ""

    // MARK: -Access to the Model
    
    @Published private var patients = [Patient]()
    
    // MARK: -Intent(s)
    
    func addPatient (patient: Patient, folder: [Patient]) {
        var folder = folder
        folder.append(patient)
        //print("Patient \(patient.id) Added.")
    }
    
    func addPatientFile (file: File, shelf: [File]) {
        
        var drawer = shelf
        drawer.append(file)
        //print("Patient \(patient.id) Added.")
    }
    
    func removePatient(_ patient: Patient) {
        
       // patients[patient] = nil
    }
    
}
