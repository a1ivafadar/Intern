//
//  Message.swift
//  Intern
//
//  Created by Ali on 12/03/21.
//

import Foundation
import CoreLocation
import MessageKit
import FirebaseAuth

struct Message: MessageType {
    public var sender: SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKind
}

enum MessageType2: String {
    case sent
    case received
}

struct Message2: Hashable, Equatable {
    let text: String
    //let audio: URL?
    let type: MessageType2
    let created: Date // Date
}

struct Msg: Hashable {
   // var id : String
    var fromId: String?
    var text : String?
    var timestamp : Int?
    var toId : String?
    var imageUrl : String?
    
    var id : String {
        if fromId == getUID(){
            return toId!
        } else {
            return fromId!
        }
    }
        
    func chatPatnerId() -> String? {
        return fromId == getUID() ? toId : fromId
    }
}

//MARK: -  function to get uid
internal func getUID() -> String {
    let uid = Auth.auth().currentUser?.uid
    return uid ?? "notFound"
}

extension MessageKind {
    var messageKindString: String {
        switch self {
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributed_text"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .custom(_):
            return "customc"
        case .linkPreview(_):
            return "link"
            
        }
    }
}

struct Sender: SenderType {
    public var photoURL: String
    public var senderId: String
    public var displayName: String
}

struct Media: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
}

struct Location: LocationItem {
    var location: CLLocation
    var size: CGSize
}
