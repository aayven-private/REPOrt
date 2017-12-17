//
//  NetworkClient.swift
//  REPOrt
//
//  Simple network client using Alamofire and RxSwift. Handles JSON and Data responses.
//
//  Created by Ivan Borsa on 15.12.17.
//  Copyright © 2017 aayven. All rights reserved.
//

import Foundation
import Alamofire
import RxSwift

protocol NetworkClientProtocol {
    func JSONrequest(endpoint: API) -> Observable<AnyObject>
    func DATArequest(endpoint: API) -> Observable<Data>
}

struct NetworkClient: NetworkClientProtocol {
    fileprivate let networkManager: Alamofire.SessionManager
    
    init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 5
        configuration.timeoutIntervalForResource = 5
        self.networkManager = Alamofire.SessionManager(configuration: configuration)
    }
    
    func JSONrequest(endpoint: API) -> Observable<AnyObject> {
        if let sampleData = endpoint.sampleData {
            return Observable.just(sampleData)
        }
        
        let safeFullUrl = self.getSafeFullUrl(endpoint: endpoint)
        
        return Observable.create { observer in
            let request = self.networkManager.request(safeFullUrl, method: endpoint.method, parameters: endpoint.parameters, encoding: endpoint.encoding, headers: endpoint.headers)
                .validate()
                .responseJSON(completionHandler: { response in
                    let error = response.result.error
                    let value = response.result.value
                    
                    if let _error = error {
                        observer.onError(_error)
                    } else if let _value = value {
                        observer.onNext(_value as AnyObject)
                        observer.onCompleted()
                    }
                })
            return Disposables.create(with: { request.cancel() })
        }
    }
    
    func DATArequest(endpoint: API) -> Observable<Data> {
        let safeFullUrl = self.getSafeFullUrl(endpoint: endpoint)
        
        return Observable.create { observer in
            let request = self.networkManager.request(safeFullUrl, method: endpoint.method, parameters: endpoint.parameters, encoding: endpoint.encoding, headers: endpoint.headers)
                .validate()
                .responseData( completionHandler: { response in
                    let error = response.result.error
                    let data = response.data
                    
                    if let _error = error {
                        observer.onError(_error)
                    } else if let _data = data {
                        observer.onNext(_data)
                        observer.onCompleted()
                    }
                })

            return Disposables.create(with: { request.cancel() })
        }
    }
}

extension NetworkClient {
    // Helper function to load stubbed responses from the specified bundle. Used for testing the requests.
    static func stubbedResponse(_ filename: String, bundle: Bundle) -> AnyObject? {
        guard let path = bundle.path(forResource: filename, ofType: "json"), let validData = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            return nil
        }
        
        do {
            let JSON = try JSONSerialization.jsonObject(with: validData, options: .allowFragments)
            return JSON as AnyObject?
        } catch {
            return nil
        }
    }
}

private extension NetworkClient {
    // Helper function cleaning the urls.
    func getSafeFullUrl(endpoint: API) -> String {
        var formattedBaseUrl = endpoint.baseUrl
        var formattedPath = endpoint.path
        
        if formattedBaseUrl.last == "/" {
            formattedBaseUrl = String(formattedBaseUrl.dropLast())
        }
        if formattedPath.first == "/" {
            formattedPath = String(formattedPath.dropFirst())
        }
        
        var fullUrl = formattedBaseUrl
        if formattedPath != "" {
            fullUrl = fullUrl + "/" + formattedPath
        }
        let safeFullUrl = fullUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? fullUrl
        
        return safeFullUrl
    }
}
