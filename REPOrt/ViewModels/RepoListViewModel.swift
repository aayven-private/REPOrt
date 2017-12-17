//
//  RepoListViewModel.swift
//  REPOrt
//
//  ViewModel for the repo list view.
//
//  Created by Ivan Borsa on 15.12.17.
//  Copyright © 2017 aayven. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import UIKit

class RepoListViewModel {
    
    // The public signals for changing the UI in the viewController
    var repoListUpdatedSignal: Driver<([RepoItem]?, Bool)> {
        return repoListUpdatedSignalSubject.asDriver(onErrorJustReturn: (nil, false))
    }
    var loadMoreResultSignal: Driver<([RepoItem]?, Bool)> {
        return loadMoreResultSignalSubject.asDriver(onErrorJustReturn: (nil, false))
    }
    var emptyViewVisibilityUpdate: Driver<Bool> {
        return emptyViewVisibilityUpdateSubject.asDriver(onErrorJustReturn: false)
    }
    var viewControllerPresentationSignal: Driver<UIViewController> {
        return viewControllerPresentationSignalSubject.asDriver(onErrorJustReturn: UIViewController())
    }
    var activityIndicatorVisibilitySignal: Driver<Bool> {
        return activityIndicatorVisibilitySignalSubject.asDriver(onErrorJustReturn: false)
    }
    
    // Private subjects for triggering the public signals. This way the viewController is a pure observer.
    fileprivate let repoListUpdatedSignalSubject = PublishSubject<([RepoItem]?, Bool)>()
    fileprivate let loadMoreResultSignalSubject = PublishSubject<([RepoItem]?, Bool)>()
    fileprivate let emptyViewVisibilityUpdateSubject = PublishSubject<Bool>()
    fileprivate let viewControllerPresentationSignalSubject = PublishSubject<UIViewController>()
    fileprivate let activityIndicatorVisibilitySignalSubject = PublishSubject<Bool>()
    
    fileprivate var reportService: REPOrtServiceProtocol
    fileprivate var disposeBag = DisposeBag()
    
    init(reportService: REPOrtServiceProtocol) {
        self.reportService = reportService
    }
    
    func handleSearchTermChanged(searchTerm: String?) {
        guard let _searchTerm = searchTerm, _searchTerm != "" else {
            self.emptyViewVisibilityUpdateSubject.onNext(true)
            self.repoListUpdatedSignalSubject.onNext(([RepoItem](), false))
            self.reportService.reset()
            return
        }
        self.activityIndicatorVisibilitySignalSubject.onNext(true)
        let repoTask = self.reportService.getRepos(searchTerm: _searchTerm).observeOn(MainScheduler.instance)
        repoTask.subscribe(onNext: { [unowned self] (items, hasMore) in
            let isVisible = (items == nil) || (items?.count == 0)
            self.emptyViewVisibilityUpdateSubject.onNext(isVisible)
            self.repoListUpdatedSignalSubject.onNext((items, hasMore))
        }, onError: { (error) in
        }, onCompleted: {
            self.activityIndicatorVisibilitySignalSubject.onNext(false)
        }).disposed(by: self.disposeBag)
    }
    
    func handleLoadMore() {
        self.activityIndicatorVisibilitySignalSubject.onNext(true)
        self.reportService.loadMore().debounce(2, scheduler: MainScheduler.instance).observeOn(MainScheduler.instance).subscribe(onNext: { [unowned self] (items, hasMore) in
            self.loadMoreResultSignalSubject.onNext((items, hasMore))
        }, onError: { (error) in
        }, onCompleted: {
            self.activityIndicatorVisibilitySignalSubject.onNext(false)
        }).disposed(by: self.disposeBag)
    }
    
    func handleImageRequest(urlString: String, forItem item: RepoItem) {
        self.reportService.loadImageFromUrlString(urlString: urlString).observeOn(MainScheduler.instance).subscribe(onNext: { (image) in
            item.avatarImage = image
            item.avatarUrlString = nil
        }, onError: { error in
            
        }, onCompleted: {
        }) {
        }.disposed(by: self.disposeBag)
    }
    
    func handleRepoItemClicked(repoItem: RepoItem) {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let detailsViewController = mainStoryboard.instantiateViewController(withIdentifier: "RepoDetailsViewController") as? RepoDetailsViewController else { return }
        let detailsViewModel = RepoDetailsViewModel(reportService: self.reportService)
        detailsViewController.viewModel = detailsViewModel
        detailsViewController.repoItem = repoItem
        self.viewControllerPresentationSignalSubject.onNext(detailsViewController)
    }
}
