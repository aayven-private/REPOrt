//
//  RepoDetailsViewController.swift
//  REPOrt
//
//  Created by Ivan Borsa on 16.12.17.
//  Copyright © 2017 aayven. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class RepoDetailsViewController: UIViewController {

    var viewModel: RepoDetailsViewModel!
    var repoItem: RepoItem!
    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var forksLabel: UILabel!
    @IBOutlet weak var subscribersLabel: UILabel!
    @IBOutlet weak var subscribersTableView: UITableView!
    @IBOutlet weak var closeButton: UIButton!
    
    fileprivate var subscribers = Variable<[String]>([])
    fileprivate var dataSource = [String]()
    fileprivate let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.subscribersTableView.delegate = self
        self.subscribersTableView.dataSource = self
        self.subscribersTableView.allowsSelection = false
        self.subscribersTableView.separatorStyle = .none
        
        self.avatarImageView.image = self.repoItem.avatarImage
        self.nameLabel.text = self.repoItem.repoName
        self.forksLabel.text = "Forks: \(self.repoItem.numForks)"
        self.subscribersLabel.text = "Subscribers: \(self.repoItem.numWatchers)"
        
        self.closeButton.rx.tap.asDriver().drive(onNext: { [unowned self] in
            self.dismiss(animated: true, completion: nil)
        }, onCompleted: {
        }) {
        }.disposed(by: self.disposeBag)
        
        self.subscribers.asDriver().drive(onNext: { (subscribers) in
            if subscribers.count < 30 {
                self.subscribersLabel.text = "Subscribers: \(subscribers.count)"
            } else if self.repoItem.numWatchers > 30 {
                self.subscribersLabel.text = "Subscribers: \(self.repoItem.numWatchers), showing first 30."
            } else  {
                self.subscribersLabel.text = "Subscribers: \(subscribers.count)"
            }
            self.dataSource = subscribers
            self.subscribersTableView.reloadData()
        }, onCompleted: {
        }) {
        }.disposed(by: self.disposeBag)
        
        self.bindViewModel()
        self.viewModel.handleSubscriberRequest(forItem: self.repoItem)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // Clean up the bindings
        super.viewWillDisappear(animated)
        self.viewModel.deactivate()
    }
}

extension RepoDetailsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SubscriberCell") else { return UITableViewCell() }
        let subscriberName = self.dataSource[indexPath.row]
        cell.textLabel?.text = subscriberName
        cell.backgroundColor = (indexPath.row % 2 == 0) ? UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1) : UIColor.white
        return cell
    }
}

private extension RepoDetailsViewController {
    func bindViewModel() {
        // Only the subscribers are loaded asynchronously as all other information is in the repo item already.
        self.viewModel.subscriberListUpdatedSignal.asObservable().takeUntil(self.viewModel.deactivateSignal).asDriver(onErrorJustReturn: []).drive(onNext: { (subscribers) in
            self.subscribers.value = subscribers
        }, onCompleted: {
        }) {
        }.disposed(by: self.disposeBag)
    }
}
