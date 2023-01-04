//
//  Name.swift
//  Intern
//
//  Created by Ali on 16/03/21.
//

import Foundation


struct Name {
    var title: String = ""
    var first: String = ""
    var last: String = ""
    var full: String {
        title + first + " " + last
    }
}
