//
//  Photo.swift
//  Virtual Tourist
//
//  Created by Luis Angel Vazquez Alor on 30.06.2020.
//  Copyright © 2020 Luis Angel Vazquez Alor. All rights reserved.
//

import Foundation

/// Structure of flickr.photos.search's method of "Photo"
struct Photo: Codable {
    
    //Optional since url_m can be empty and cause parsing issues
    let imageURL: String?
    
    enum CodingKeys: String, CodingKey{
        case imageURL = "url_m"
    }
}
