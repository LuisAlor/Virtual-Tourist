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
    
    enum Endpoints {
        
        //Base Flickr API URL
        static let baseURL = "https://www.flickr.com/services/rest/?method="
        
        case searchPhotos(latitude:Double, longitude:Double)
        
        var stringURL: String{
            switch self {
            //searchPhotos API Method flickr.photos.search
            case let .searchPhotos(latitude, longitude):
                return Endpoints.baseURL + "flickr.photos.search&" + "api_key=\(FlickrClient.apiKey)&" + "sort=date-posted-asc&" +
                    "&privacy_filter=1" + "media=photos&" + "lat=\(latitude)&lon=\(longitude)&" + "extras=url_m&" + "per_page=5&" + "page=\(Int.random(in: 0..<100))&" + "format=json&nojsoncallback=1"
            }
        }
        // Return from our generated URL type string to URL
        var url: URL{
            return URL(string: stringURL)!
        }
    }
    
    /// Generic Get Request usuable only inside FlickrClient
    private class func sendGETRequest<ResponseType: Decodable>(url: URL, response: ResponseType.Type, completionHandler: @escaping (ResponseType?,Error?) -> Void ){
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    completionHandler(nil,error)
                }
                return
            }
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completionHandler(responseObject,nil)
                }
            }
            catch {
                DispatchQueue.main.async {
                    completionHandler(nil, error)
                }
            }
        }
        task.resume()
    }
    
    /// Downloads an image from Flickr servers into our device
    public class func downloadImage(imageURL: URL, completionHandler: @escaping (Data?, Error?) -> Void ){
                
        let task = URLSession.shared.dataTask(with: imageURL) { (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    completionHandler(nil, error)
                }
            return
            }
            DispatchQueue.main.async {
                completionHandler(data,nil)
            }
        }
        task.resume()
    }
    /// Returns an array of [Photo]'s by the latitude and longitude provided
    public class func flickrGETSearchPhotos(lat: Double, lon: Double, completionHandler: @escaping ([Photo], Error?) -> Void ){
        
        sendGETRequest(url: Endpoints.searchPhotos(latitude: lat, longitude: lon).url, response: PhotosSearchResponse.self) { (response, error) in
            if let response = response {
                completionHandler(response.photos.photo, nil)
            } else {
                completionHandler([], error)
            }
        }
    }
    
}


