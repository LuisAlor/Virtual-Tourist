//
//  FlickrKeys.swift
//  Virtual Tourist
//
//  Created by Luis Angel Vazquez Alor on 27.06.2020.
//  Copyright © 2020 Luis Angel Vazquez Alor. All rights reserved.
//

import Foundation

///Flickr PList Structure that subclasses Codable Protocol
struct FlickrKeys: Codable{
    let apiKey: String
    let secretKey: String
}
