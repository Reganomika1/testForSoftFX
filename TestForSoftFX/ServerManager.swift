//
//  ServerMamager.swift
//  PressFeed
//
//  Created by Artem on 21.08.17.
//  Copyright © 2017 BalinaSoft. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import SwiftyXMLParser

class ServerManager {

    static let shared = ServerManager()
    let baseUrl = "https://widgets.spotfxbroker.com:8088/"
    typealias Completion = (Bool, JSON?, String?) -> ()
    
    
    //MARK: - Get requests
    
    func getLiveNews( completion: @escaping Completion) {
    
        
        Alamofire.request(baseUrl + "GetLiveNewsRss", method:.get, parameters: nil, headers: nil).response {
            response in
            let status = response.response?.statusCode
            let data = response.data
            if let status = status {
                if status == 200 {
                    if let data = data {
                        let xml = JSON(data: data)
                        print(xml)
                        completion(true, nil, nil)
                    } else {
                        completion(true, nil, nil)
                    }
                } else if status >= 500 {
                    completion(false, nil, "Сервер не работает")
                } else {
                    if let data = data {
                        let json = JSON(data: data)
                        print(json)
                        let message = json["message"].string
                        completion(false, json, message)
                    }
                    completion(false, nil, nil)
                }
            }else {
                completion(false, nil, "Превышено время ожидания отклика сервера. Возможно утрачено интернет-соединение.")
            }
        }
    }
}















