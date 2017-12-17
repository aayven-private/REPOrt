//
//  RepoItem.swift
//  REPOrt
//
//  Repo item object describing the repository query results.
//
//  Created by Ivan Borsa on 15.12.17.
//  Copyright © 2017 aayven. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

enum JSONParsingError: Error {
    case InvalidJSON
    case FieldNotFound
    case Unknown
    
    var message: String {
        get {
            switch self {
            case .InvalidJSON:
                return "Invalid JSON!"
            case .FieldNotFound:
                return "Mandatory field missing!"
            case .Unknown:
                return "Unknown error!"
            }
        }
    }
}

class RepoItem {
    // Notify subscribers on image change so they can act on it.
    var avatarImage: UIImage {
        didSet {
            self.imageChangedSignalSubject.onNext(self.avatarImage)
        }
    }
    let ownerName: String
    var avatarUrlString: String?
    let repoName: String
    let repoDescription: String?
    let numForks: Int
    let numWatchers: Int
    let subscribersUrlString: String?
    
    var imageChangedSignal: Driver<UIImage> {
        return imageChangedSignalSubject.asDriver(onErrorJustReturn: UIImage(named: "default_avatar") ?? UIImage())
    }
    
    // Deinit signal for the item so that subscribers can let bindings go.
    let deinitSignal = PublishSubject<Void>()
    fileprivate let imageChangedSignalSubject = PublishSubject<UIImage>()
    fileprivate let disposeBag = DisposeBag()
    
    init(ownerName: String, avatarImage: UIImage, avatarUrlString: String?, repoName: String, repoDescription: String?, numForks: Int, numWatchers: Int, subscribersUrlString: String?) {
        self.avatarImage = avatarImage
        self.avatarUrlString = avatarUrlString
        self.repoName = repoName
        self.repoDescription = repoDescription
        self.numForks = numForks
        self.subscribersUrlString = subscribersUrlString
        self.numWatchers = numWatchers
        self.ownerName = ownerName
    }
    
    deinit {
        self.deinitSignal.onNext(())
    }
    
    // Statuc function parsing the JSON to item list.
    static func jsonToList(_ json: AnyObject?) throws -> ([RepoItem]?, Int) {
        var result = [RepoItem]()
        
        guard let unwrappedJson = json as? [String: AnyObject] else { throw JSONParsingError.InvalidJSON }
        guard let items = unwrappedJson["items"] as? [AnyObject] else { return (nil, 0) }
        let totalCount = unwrappedJson["total_count"] as? Int ?? 0
        for itemJson in items {
            let item = try RepoItem.jsonToItem(itemJson)
            result.append(item)
        }
        
        return (result, totalCount)
    }
    
    //Static function parsing the JSON to a repo item
    static func jsonToItem(_ json: AnyObject?) throws -> RepoItem {
        guard let unwrappedJson = json as? [String: AnyObject] else { throw JSONParsingError.InvalidJSON }
        guard let repoName = unwrappedJson["name"] as? String else { throw JSONParsingError.FieldNotFound }
        guard let ownerObject = unwrappedJson["owner"] as? [String: AnyObject] else { throw JSONParsingError.FieldNotFound }
        let avatarUrlString = ownerObject["avatar_url"] as? String ?? nil
        let ownerName = ownerObject["login"] as? String ?? "Unknown"
        let repoDescription = unwrappedJson["description"] as? String ?? nil
        let numForks = unwrappedJson["forks_count"] as? Int ?? 0
        let numWatchers = unwrappedJson["watchers_count"] as? Int ?? 0
        let subscribersUrlString = unwrappedJson["subscribers_url"] as? String ?? nil
        
        return RepoItem(ownerName: ownerName, avatarImage: UIImage(named: "default_avatar") ?? UIImage(), avatarUrlString: avatarUrlString, repoName: repoName, repoDescription: repoDescription, numForks: numForks, numWatchers: numWatchers, subscribersUrlString: subscribersUrlString)
    }
}
