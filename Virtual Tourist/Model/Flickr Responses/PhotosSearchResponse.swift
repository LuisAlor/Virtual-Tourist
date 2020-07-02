//
//  PhotosSearchResponse.swift
//  Virtual Tourist
//
//  Created by Luis Angel Vazquez Alor on 30.06.2020.
//  Copyright © 2020 Luis Angel Vazquez Alor. All rights reserved.
//

import Foundation

/// Structure of flickr.photos.search's method root response 
struct PhotosSearchResponse: Codable {
    let photos: Photos
    let stat: String
}
