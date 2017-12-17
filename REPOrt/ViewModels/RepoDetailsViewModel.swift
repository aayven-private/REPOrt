//
//  RepoDetailsViewModel.swift
//  REPOrt
//
//  ViewModel for the repo details view.
//
//  Created by Ivan Borsa on 16.12.17.
//  Copyright © 2017 aayven. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import UIKit

class RepoDetailsViewModel {
    var subscriberListUpdatedSignal: Driver<[String]> {
        return subscriberListUpdatedSignalSubject.asDriver(onErrorJustReturn: [String]())
    }
    
    let deactivateSignal = PublishSubject<Void>()
    
    fileprivate let subscriberListUpdatedSignalSubject = PublishSubject<[String]>()
    
    fileprivate var reportService: REPOrtServiceProtocol
    fileprivate var disposeBag = DisposeBag()
    
    init(reportService: REPOrtServiceProtocol) {
        self.reportService = reportService
    }
    
    func handleSubscriberRequest(forItem repoItem: RepoItem) {
        guard let urlString = repoItem.subscribersUrlString else { return }
        self.reportService.getSubscribers(urlString: urlString).observeOn(MainScheduler.instance).subscribe(onNext: { [unowned self] (subscribers) in
            self.subscriberListUpdatedSignalSubject.onNext(subscribers)
        }, onError: { (error) in
            
        }, onCompleted: {
        }) {
        }.disposed(by: self.disposeBag)
    }
    
    func deactivate() {
        self.deactivateSignal.onNext(())
    }
}
