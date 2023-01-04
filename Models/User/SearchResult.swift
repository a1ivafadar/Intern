//
//  SearchResult.swift
//  Messenger
//
//  Created by Afraz Siddiqui on 6/20/20.
//  Copyright © 2020 ASN GROUP LLC. All rights reserved.
//

import Foundation

struct SearchResult: Identifiable {
    let id = UUID()
    let name: String
    let email: String
}
