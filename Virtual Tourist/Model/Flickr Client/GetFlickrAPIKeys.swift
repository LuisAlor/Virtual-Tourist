//
//  GetFlickrAPIKeys.swift
//  Virtual Tourist
//
//  Created by Luis Angel Vazquez Alor on 27.06.2020.
//  Copyright © 2020 Luis Angel Vazquez Alor. All rights reserved.
//

import Foundation

///Get user's Flickr  Keys in order to work with API
enum GetFlickrAPIKeys {
    
    case apiKey
    case secretKey
    
    //Private computed property for getting the keys from property list
    private var getKeys: FlickrKeys? {
        
        guard let url = Bundle.main.url(forResource: "FlickrKeys", withExtension: "plist") else { return nil }
        if let data = try? Data(contentsOf: url) {
            let decoder = PropertyListDecoder()
            do {
                let keysDict = try decoder.decode(FlickrKeys.self, from: data)
                return keysDict
            }
            catch{
                fatalError("Something went wrong: \(error.localizedDescription)")
            }
        } else {
            return nil
        }
    }
    //Get the API Key stored from PList
    public var getApiKey: String{
        if let apiKey = getKeys?.apiKey{
            return apiKey
        } else{
            return ""
        }
    }
    //Get the Secret Key stored from PList
    public var getSecretKey: String{
        if let secretKey = getKeys?.secretKey{
            return secretKey
        } else{
            return ""
        }
    }
}


