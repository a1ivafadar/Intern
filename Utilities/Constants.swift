//
//  Constants.swift
//  ChatApp
//
//  Created by Aaryan Kothari on 03/06/20.
//  Copyright © 2020 Aaryan Kothari. All rights reserved.
//


import Foundation
import Firebase
import FirebaseAuth

////MARK: -  function to get uid
//internal func getUID() -> String {
//    let uid = Auth.auth().currentUser?.uid
//    return uid ?? "notFound"
//}


public func debugLog(message: String) {
    #if DEBUG
    debugPrint("=======================================")
    debugPrint(message)
    debugPrint("=======================================")
    #endif
}

struct Constants {
    static var hubName = ""
    static var connectionString = ""

    static var displayName = ""
    static var identifier = ""
    static var token = ""
    static var callee = ""
}
