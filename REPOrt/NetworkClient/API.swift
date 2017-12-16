//
//  API.swift
//  REPOrt
//
//  Created by Ivan Borsa on 15.12.17.
//  Copyright © 2017 aayven. All rights reserved.
//

import Alamofire

protocol API {
    var baseUrl: String { get }
    var path: String { get }
    var parameters: Parameters? { get }
    var method: HTTPMethod { get }
    var encoding: ParameterEncoding { get }
    var headers: HTTPHeaders? { get }
    var sampleData: AnyObject? { get }
}
