//
//  REPOrtTests.swift
//  REPOrtTests
//
//  Created by Ivan Borsa on 15.12.17.
//  Copyright © 2017 aayven. All rights reserved.
//

import XCTest
import RxSwift
@testable import REPOrt

class REPOrtTests: XCTestCase {
    
    var disposeBag: DisposeBag!
    var networkClient: NetworkClient!
    var repoService: REPOrtServiceProtocol!
    
    override func setUp() {
        super.setUp()
        
        disposeBag = DisposeBag()
        networkClient = NetworkClient()
        
        let testBundle = Bundle(for: REPOrtTests.self)
        let get_repos_response = NetworkClient.stubbedResponse("get_repos", bundle: testBundle)!
        let get_subscribers_response = NetworkClient.stubbedResponse("get_subscribers", bundle: testBundle)!
        let sampleDataDictionary = ["get_repos": get_repos_response, "get_subscribers": get_subscribers_response]
        
        repoService = REPOrtService(networkClient: networkClient, sampleDataDictionary: sampleDataDictionary)
    }
    
    override func tearDown() {
        disposeBag = nil
        networkClient = nil
        repoService = nil
        super.tearDown()
    }
    
    func testGetRepos() {
        let currentExpectation = expectation(description: "get_repos")
        var _items: [RepoItem]? = nil
        var _hasMore = false
        
        repoService.getRepos(searchTerm: "google").observeOn(MainScheduler.instance).subscribe(onNext: { (items, hasMore) in
            _items = items
            _hasMore = hasMore
        }, onError: { (error) in
            
        }, onCompleted: {
            currentExpectation.fulfill()
        }) {
        }.disposed(by: self.disposeBag)
        
        waitForExpectations(timeout: 5) { error in
            if let _error = error {
                XCTFail("Failed with error: \(_error)")
            }
            
            XCTAssertNotNil(_items)
            XCTAssertEqual(10, _items!.count)
            XCTAssertTrue(_hasMore)
            
            let firstItem = _items![0]
            XCTAssertEqual(firstItem.avatarUrlString, "https://avatars1.githubusercontent.com/u/227923?v=4")
            XCTAssertEqual(firstItem.numForks, 272)
            XCTAssertEqual(firstItem.ownerName, "MarioVilas")
            XCTAssertEqual(firstItem.repoName, "google")
            XCTAssertEqual(firstItem.repoDescription, "Google search from Python.")
            XCTAssertEqual(firstItem.subscribersUrlString, "https://api.github.com/repos/MarioVilas/google/subscribers")
        }
    }
    
    func testGetSubscribers() {
        let currentExpectation = expectation(description: "get_subscribers")
        var _subscribers: [String]? = nil
        
        repoService.getSubscribers(urlString: ":)").observeOn(MainScheduler.instance).subscribe(onNext: { subscribers in
            _subscribers = subscribers
        }, onError: { (error) in
            
        }, onCompleted: {
            currentExpectation.fulfill()
        }) {
        }.disposed(by: self.disposeBag)
        
        waitForExpectations(timeout: 5) { error in
            if let _error = error {
                XCTFail("Failed with error: \(_error)")
            }
            
            XCTAssertNotNil(_subscribers)
            XCTAssertEqual(10, _subscribers!.count)
            
            
            XCTAssertEqual(_subscribers![0], "MarioVilas")
        }
    }
}
