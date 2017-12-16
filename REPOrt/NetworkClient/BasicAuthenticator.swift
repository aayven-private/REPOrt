//
//  BasicAuthenticator.swift
//  REPOrt
//
//  Created by Ivan Borsa on 15.12.17.
//  Copyright © 2017 aayven. All rights reserved.
//

import RxSwift
import Alamofire

struct BasicAuthenticator {
    fileprivate let username: String
    fileprivate let password: String
    
    init(username: String, password: String) {
        self.username = username
        self.password = password
    }
}

extension BasicAuthenticator {
    func authHeader() -> [String: String] {
        let credentialData = "\(username):\(password)".data(using: String.Encoding.utf8)!
        let base64Credentials = credentialData.base64EncodedString(options: [])
        return ["Authorization": "Basic \(base64Credentials)"]
    }
}
