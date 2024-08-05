//
//  Constants.swift
//  ChatAppSwiftUI
//
//  Created by Gaurav Abbhi on 21/5/2024.
//

import Foundation
import Firebase

struct FirestoreConstants {
    
    static let userCollection = Firestore.firestore().collection("users")
    static let messageCollection = Firestore.firestore().collection("messages")
    
}
