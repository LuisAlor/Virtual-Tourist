//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Luis Angel Vazquez Alor on 27.06.2020.
//  Copyright © 2020 Luis Angel Vazquez Alor. All rights reserved.
//

import Foundation

///Flickr Client Class to work with API User's Request
class FlickrClient {
    
    //Get our user stored apiKey for Flickr
    static let apiKey = GetFlickrAPIKeys.apiKey.getApiKey
    //Get our user stored secretKey for Flickr
    static let secretKey = GetFlickrAPIKeys.secretKey.getSecretKey
    
}
