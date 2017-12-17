//
//  REPOrtAPI.swift
//  REPOrt
//
//  Enum describing the GitHub API (or a tiny subset of it that we are using)
//
//  Created by Ivan Borsa on 15.12.17.
//  Copyright © 2017 aayven. All rights reserved.
//

import Foundation
import Alamofire
import RxSwift

enum REPOrtAPI: API {
    case getRepos(searchTerm: String, pagination: Pagination, sampleData: AnyObject?)
    case getImage(urlString: String)
    case getSubscribers(urlString: String, sampleData: AnyObject?)
}

extension REPOrtAPI {
    var baseUrl: String {
        switch self {
        case .getImage(let urlString), .getSubscribers(let urlString, _):
            return urlString
        default:
            return "https://api.github.com"
        }
    }
    
    var path: String {
        switch self {
        case .getRepos:
            return "/search/repositories"
        case .getImage, .getSubscribers:
            return ""
        }
    }
    
    var parameters: Parameters? {
        switch self {
        case .getRepos(let searchTerm, let pagination, _):
            return ["q": searchTerm, "page": pagination.pageNum, "per_page": pagination.perPage]
        default:
            return nil
        }
    }
    
    var method: HTTPMethod {
        return .get
    }
    
    var encoding: ParameterEncoding {
        return URLEncoding.queryString
    }
    
    var headers: HTTPHeaders? {
        return nil
    }
    
    var sampleData: AnyObject? {
        switch self {
        case .getRepos(_, _, let sampleData), .getSubscribers(_, let sampleData):
            return sampleData
        default:
            return nil
        }
    }
}
