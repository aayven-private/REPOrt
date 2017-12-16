//
//  RepoListCell.swift
//  REPOrt
//
//  Created by Ivan Borsa on 15.12.17.
//  Copyright © 2017 aayven. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class RepoListCell: UITableViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var forksLabel: UILabel!
    
    fileprivate let disposeBag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func setupWithRepoItem(repoItem: RepoItem) {
        self.avatarImageView.image = repoItem.avatarImage
        self.nameLabel.text = "Name: \(repoItem.repoName)"
        self.forksLabel.text = "Forks: \(repoItem.numForks)"
        self.descriptionLabel.text = repoItem.repoDescription
        
        repoItem.imageChangedSignal.asObservable().takeUntil(repoItem.deinitSignal).asDriver(onErrorJustReturn: UIImage()).drive(onNext: { [unowned self] (image) in
            self.avatarImageView.image = image
        }, onCompleted: {
        }) {
        }.disposed(by: self.disposeBag)
    }

}
