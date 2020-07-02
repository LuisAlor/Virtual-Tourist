//
//  Photos.swift
//  Virtual Tourist
//
//  Created by Luis Angel Vazquez Alor on 30.06.2020.
//  Copyright © 2020 Luis Angel Vazquez Alor. All rights reserved.
//

import Foundation

/// Structure of flickr.photos.search's method of "Photos" 
struct Photos: Codable {
    let page: Int
    let pages: Int
    let perPage: Int
    let total: String
    let photo: [Photo]
    
    enum CodingKeys: String, CodingKey {
        case page
        case pages
        case perPage = "perpage"
        case total
        case photo
    }
}
