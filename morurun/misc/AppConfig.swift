//
//  AppConfig.swift
//  morurun
//
//  Created by watanabe on 2016/11/04.
//  Copyright © 2016年 Crypton Future Media, INC. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift

class AppConfig {

    static let shared = AppConfig()
    
    private init() {}
    
    var nickname: UserDefalutsValues<String> {
        get {
            return UserDefalutsValues<String>(propertyName: #function)
        }
    }
    var uid: UserDefalutsValues<String> {
        get {
            return UserDefalutsValues<String>(propertyName: #function)
        }
    }
    #if DEVELOP
    var debugUrlString: UserDefalutsValues<String> {
        get {
            return UserDefalutsValues<String>(propertyName: #function)
        }
    }
    #endif
}

class UserDefalutsValues<Type>: ReactiveCompatible {
    
    private(set) var userDefaults: UserDefaults
    private(set) var propertyName: String
    required init(userDefaults: UserDefaults = UserDefaults.standard , propertyName: String) {
        self.userDefaults = userDefaults
        self.propertyName = propertyName
    }
    
    var value: Type? {
        get {
            return self.userDefaults.object(forKey: self.propertyName) as? Type
        }
        set {
            self.userDefaults.set(newValue, forKey: self.propertyName)
            assert(self.userDefaults.synchronize())
        }
    }
}
