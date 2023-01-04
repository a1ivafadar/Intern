//
//  File.swift
//  Intern
//
//  Created by Ali on 11/03/21.
//

import Foundation

struct File {
    
    var history: History
    var treatments: Treatments
    var medications: Medications
    var allergies: Allergies
    var demographics: Demographics
    var measurements: Measurements
    
    struct Demographics {
        var sex: String
        var age: Int
        var race: String
        var education: String
    }
    
    struct Measurements {
        var height: String
        var weight: String
        var bmi: String
    }
    
    struct Allergies {
        
    }
    
    struct Medications {
        
    }
    
    struct Treatments {
        
    }
}
