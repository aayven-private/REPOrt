//
//  RepoListViewController.swift
//  REPOrt
//
//  Created by Ivan Borsa on 15.12.17.
//  Copyright © 2017 aayven. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class RepoListViewController: UIViewController {

    var viewModel: RepoListViewModel!
    
    @IBOutlet weak var searchField: UITextField!
    @IBOutlet weak var repoTableView: UITableView!
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var launchScreenLabel: UILabel!
    
    fileprivate var repoItems = Variable(([RepoItem](), false))
    fileprivate var dataSource = [Any]()
    fileprivate let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardNotification(notification:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        
        self.repoTableView.delegate = self
        self.repoTableView.dataSource = self
        self.repoTableView.separatorStyle = .none
        
        // Observing the repo list, in case we have more results, add a load more cell at the bottom
        self.repoItems.asDriver().drive(onNext: { [unowned self] (items, hasMore) in
            self.dataSource = items
            if hasMore {
                self.dataSource.append("LOAD MORE")
            }
            self.reloadTable()
        }, onCompleted: {
        }) {
        }.disposed(by: self.disposeBag)
        
        self.bindViewModel()
        
        UIView.animate(withDuration: 0.5) { [unowned self] in
            self.launchScreenLabel.alpha = 0.0
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension RepoListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellItem = self.dataSource[indexPath.row]
        
        if let repoItem = cellItem as? RepoItem {
            // Repo cell
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "RepoListCell", for: indexPath) as? RepoListCell else { return UITableViewCell() }
            cell.setupWithRepoItem(repoItem: repoItem)
            if let avatarUrlString = repoItem.avatarUrlString {
                self.viewModel.handleImageRequest(urlString: avatarUrlString, forItem: repoItem)
            }
            return cell
        } else if let loadMoreString = cellItem as? String {
            // Load more cell
            let cell = UITableViewCell()
            cell.textLabel?.text = loadMoreString
            cell.textLabel?.textAlignment = .center
            cell.backgroundColor = UIColor.darkGray
            cell.textLabel?.textColor = UIColor.white
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let cellData = dataSource[indexPath.row]
        
        if let _ = cellData as? String {
            // Load more
            self.viewModel.handleLoadMore()
        } else if let repoItem = cellData as? RepoItem {
            // Show details screen
            self.viewModel.handleRepoItemClicked(repoItem: repoItem)
        }
    }
}

private extension RepoListViewController {
    func bindViewModel() {
        // Observing the search field text. Debounce to avoid continous seach while typing
        self.searchField.rx.text.asObservable().debounce(1, scheduler: MainScheduler.instance).distinctUntilChanged({ (n1, n2) -> Bool in
            n1 == n2
        }).subscribe(onNext: { [unowned self] (text) in
            self.dataSource = [RepoItem]()
            self.reloadTable(shouldKeepOffset: false)
            self.viewModel.handleSearchTermChanged(searchTerm: text)
        }, onError: { (error) in
            
        }, onCompleted: {
        }) {
        }.disposed(by: self.disposeBag)
        
        // Repo list updated so act on it!
        self.viewModel.repoListUpdatedSignal.drive(onNext: { [unowned self] (items, hasMore) in
            guard let _items = items else { return }
            self.repoItems.value = (_items, hasMore)
        }, onCompleted: {
        }) {
        }.disposed(by: self.disposeBag)
        
        // New page loaded, we append the new results to the end.
        self.viewModel.loadMoreResultSignal.drive(onNext: { (items, hasMore) in
            guard let _items = items else { return }
            var currentItems = self.repoItems.value.0
            currentItems.append(contentsOf: _items)
            self.repoItems.value = (currentItems, hasMore)
        }, onCompleted: {
        }) {
        }.disposed(by: self.disposeBag)
        
        // Empty view visibility update
        self.viewModel.emptyViewVisibilityUpdate.drive(onNext: { [unowned self] (isVisible) in
            self.emptyView.isHidden = !isVisible
        }, onCompleted: {
        }) {
        }.disposed(by: self.disposeBag)
        
        // View controller presentation handler. Details page openinng triggers it.
        self.viewModel.viewControllerPresentationSignal.drive(onNext: { [unowned self] viewController in
            self.present(viewController, animated: true, completion: nil)
        }, onCompleted: {
        }) {
        }.disposed(by: self.disposeBag)
        
        // Activity indicator visibility update.
        self.viewModel.activityIndicatorVisibilitySignal.drive(onNext: { [unowned self] (isVisible) in
            if isVisible {
                self.activityIndicator.startAnimating()
            } else {
                self.activityIndicator.stopAnimating()
            }
        }, onCompleted: {
            
        }).disposed(by: self.disposeBag)
    }
}

private extension RepoListViewController {
    // Animate layout chenge on keyboard hide / show
    @objc func keyboardNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let endFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let duration:TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIViewAnimationOptions.curveEaseInOut.rawValue
            let animationCurve:UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
            var isKeyboardVisible = false
            
            if (endFrame?.origin.y)! >= UIScreen.main.bounds.size.height {
                //Keyboard not visible
                self.bottomConstraint?.constant = 0.0
            } else {
                //Keyboard visible
                isKeyboardVisible = true
                self.bottomConstraint?.constant = ((endFrame?.size.height) ?? 0.0)
            }
            
            let contentInsets: UIEdgeInsets = isKeyboardVisible ? (UIEdgeInsetsMake(0.0, 0.0, endFrame?.size.height ?? 0.0, 0.0)) : (UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0))
            self.repoTableView.contentInset = contentInsets
            UIView.animate(withDuration: duration,
                           delay: TimeInterval(0),
                           options: animationCurve,
                           animations: {
                            self.view.layoutIfNeeded()
            },
                           completion: { [unowned self] finished in
                            if finished {
                                self.repoTableView.contentInset = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0)
                            }
            })
        }
    }
}

private extension RepoListViewController {
    func reloadTable(shouldKeepOffset: Bool = true) {
        // Reloads the tableview content, keeps offset if necessary (on load more when we don't want to scroll to the top)
        let lastScrollOffset = self.repoTableView.contentOffset
        self.repoTableView.reloadData()
        self.repoTableView.layer.removeAllAnimations()
        if shouldKeepOffset {
            self.repoTableView.setContentOffset(lastScrollOffset, animated: false)
        }
    }
}

