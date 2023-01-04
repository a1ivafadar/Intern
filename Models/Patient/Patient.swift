//
//  Patient.swift
//  Intern
//
//  Created by Ali on 08/03/21.
//

import SwiftUI

class Patient: ObservableObject, Identifiable {
    var id = UUID().uuidString
    var name = Name()
    var age = ""
    var sex = ""

}
