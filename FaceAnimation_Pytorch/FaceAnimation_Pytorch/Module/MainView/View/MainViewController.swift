//
//  ViewController.swift
//  FaceAnimation_Pytorch
//
//  Created by zhangerbing on 2021/9/16.
//

import UIKit
import RxSwift
import RxCocoa
import NSObject_Rx

class MainViewController: UIViewController, StoryboardInitializable {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var tableView: UITableView!
    
    var viewModel: MainViewModel!
    
    // MARK: - View life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        bindViewModel()
    }
    
    private func setupUI() {
        // Do any additional setup after loading the view.
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        tableView.tableFooterView = UIView()
        
        logInfo("准备就绪")
    }
    
    private func bindViewModel() {
        viewModel.image.bind(to: imageView.rx.image).disposed(by: rx.disposeBag)
        
        viewModel.list.bind(to: tableView.rx.items(cellIdentifier: "cell", cellType: MainTableViewCell.self)) { _, title, cell in
            cell.titleLabel.text = title
        }.disposed(by: rx.disposeBag)
     
        tableView.rx.modelSelected(String.self)
            .bind(to: viewModel.execute)
            .disposed(by: rx.disposeBag)
    }
}

extension MainViewController {
    private func logInfo(_ info: String) {
        let prefix = "输出台:\n\n"
        textView.text = prefix + info
    }
}
