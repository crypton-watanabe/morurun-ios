//
//  URLManager.swift
//  morurun
//
//  Created by watanabe on 2016/11/08.
//  Copyright © 2016年 Crypton Future Media, INC. All rights reserved.
//

import Foundation

class URLManager {
    
    private static var instance = URLManager()
    private let baseUrl: URL
    private let version: String

    init?(baseUrlString: String, version: String) {
        if let url = URL(string: baseUrlString) {
            self.baseUrl = url
            self.version = version
        }
        else {
            return nil
        }
    }

    convenience init() {
        var baseUrlString = Bundle.main.infoDictionary!["Morurun URL"] as! String
        #if DEVELOP
        if let debugUrlString = AppConfig.shared.debugUrlString.value {
            baseUrlString = debugUrlString
        }
        #endif
        self.init(baseUrlString: baseUrlString, version: "v1")!
    }

    class var shared: URLManager {
        return instance;
    }
    
    private func generateURLString(_ baseUrl: URL, urlComponents: String...) -> URL {
        var url = baseUrl
        for component in urlComponents {
            url = url .appendingPathComponent(component)
        }
        return url
    }
    
    var setupUser: URL {
        get {
            return self.generateURLString(self.baseUrl, urlComponents: version, #function)
        }
    }
    var getPostings: URL {
        get {
            return self.generateURLString(self.baseUrl, urlComponents: version, #function)
        }
    }
    var postData: URL {
        get {
            return self.generateURLString(self.baseUrl, urlComponents: version, #function)
        }
    }
    var getLocations: URL {
        get {
            return self.generateURLString(self.baseUrl, urlComponents: version, #function)
        }
    }
}
