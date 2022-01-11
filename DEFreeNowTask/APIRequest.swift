//
//  APIRequest.swift
//  DEFreeNowTask
//
//  Created by Kerem on 26.12.2021.
//

import Foundation

class APIRequest {
    let url: URL
    
    init(url: URL) {
        self.url = url
    }
    
    func perform<T: Decodable>(with completion: @escaping (T?) -> Void) {
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        //let session = URLSession(configuration: .default, delegate: nil, delegateQueue: .main)
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                completion(nil)
                return
            }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            completion(try? decoder.decode(T.self, from: data))
        }
        task.resume()
    }
}

