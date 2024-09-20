//
//  Comment.swift
//  project-2-lousalvant
//
//  Created by Lou-Michael Salvant on 9/20/24.
//

import Foundation
import ParseSwift

struct Comment: ParseObject {
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    var username: String?
    var content: String?
}
