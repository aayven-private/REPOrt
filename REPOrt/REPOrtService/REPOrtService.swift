//
//  REPOrtService.swift
//  REPOrt
//
//  Service class handling the requests initiated by the user.
//  The methods create observables that can be observed in the view models and act on changes accordingly.
//
//  Created by Ivan Borsa on 15.12.17.
//  Copyright © 2017 aayven. All rights reserved.
//

import Foundation
import RxSwift

protocol REPOrtServiceProtocol: class {
    init(networkClient: NetworkClientProtocol, sampleDataDictionary: [String: AnyObject]?)
    
    func reset()
    
    func getRepos(searchTerm: String) -> Observable<([RepoItem]?, Bool)>
    func loadMore() -> Observable<([RepoItem]?, Bool)>
    func loadImageFromUrlString(urlString: String) -> Observable<UIImage>
    func getSubscribers(urlString: String) -> Observable<[String]>
}

final class REPOrtService: REPOrtServiceProtocol {
    fileprivate let networkClient: NetworkClientProtocol
    fileprivate let pagination = Pagination()
    fileprivate var searchTerm: String = ""
    fileprivate var sampleDataDictionary: [String: AnyObject]? = nil
    
    init(networkClient: NetworkClientProtocol, sampleDataDictionary: [String: AnyObject]? = nil) {
        self.networkClient = networkClient
        self.sampleDataDictionary = sampleDataDictionary
    }
    
    // Resets pagination and search term. Used when search text changed.
    func reset() {
        self.pagination.pageNum = 1
        self.searchTerm = ""
    }
    
    // Resturns an observable sequence producing the repo item list and a hasMore flag
    func getRepos(searchTerm: String) -> Observable<([RepoItem]?, Bool)> {
        self.pagination.pageNum = 1
        self.searchTerm = searchTerm
        let repoEndpoint = REPOrtAPI.getRepos(searchTerm: self.searchTerm, pagination: self.pagination, sampleData: getSampleData(forEndpointName: "get_repos"))
        return networkClient.JSONrequest(endpoint: repoEndpoint).map(toRepoItems)
    }
    
    // Resturns an observable sequence producing the upcoming page for the previously specified search term and a hasMore flag.
    func loadMore() -> Observable<([RepoItem]?, Bool)> {
        self.pagination.pageNum = pagination.pageNum + 1
        let repoEndpoint = REPOrtAPI.getRepos(searchTerm: self.searchTerm, pagination: self.pagination, sampleData: getSampleData(forEndpointName: "load_more"))
        return networkClient.JSONrequest(endpoint: repoEndpoint).map(toRepoItems)
    }
    
    // Downloads an image from a given url. Used for asynchronously downloading the avatar images.
    func loadImageFromUrlString(urlString: String) -> Observable<UIImage> {
        let imageEndpoint = REPOrtAPI.getImage(urlString: urlString)
        return networkClient.DATArequest(endpoint: imageEndpoint).map(toAvatarImage)
    }
    
    // Downloads the subscriber list from the given url.
    func getSubscribers(urlString: String) -> Observable<[String]> {
        let subscribersEndpoint = REPOrtAPI.getSubscribers(urlString: urlString, sampleData: getSampleData(forEndpointName: "get_subscribers"))
        return networkClient.JSONrequest(endpoint: subscribersEndpoint).map(toSubscribersList)
    }
}

private extension REPOrtService {
    func toRepoItems(json: AnyObject) throws -> ([RepoItem]?, Bool) {
        let result = try RepoItem.jsonToList(json)
        
        let items = result.0
        let totalCount = result.1
        
        let hasMore = totalCount > pagination.pageNum * pagination.perPage
        return (items, hasMore)
    }
    
    func toAvatarImage(data: Data) -> UIImage {
        if let image = UIImage(data: data) {
            return image
        }
        return UIImage(named: "default_avatar") ?? UIImage()
    }
    
    func toSubscribersList(json: AnyObject) throws -> [String] {
        guard let unwrappedJson = json as? [AnyObject] else { throw JSONParsingError.InvalidJSON }
        let result = unwrappedJson.map { (item) -> String in
            let subscriberName = item["login"] as? String ?? "Unknown"
            return subscriberName
        }
        return result
    }
}

private extension REPOrtService {
    func getSampleData(forEndpointName name: String) -> AnyObject? {
        guard let _sampleDataDictionary = sampleDataDictionary else { return nil }
        let sampleData = _sampleDataDictionary[name]
        return sampleData
    }
}
