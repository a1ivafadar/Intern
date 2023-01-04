//
//  Books.swift
//  Lego
//
//  Created by Ali on 13/03/21.
//

import Foundation

class Books: Codable, Identifiable
{
    var id: UUID

    var name: String
    var bookCover: String
}
