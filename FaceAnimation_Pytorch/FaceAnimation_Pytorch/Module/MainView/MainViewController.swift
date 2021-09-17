//
//  ViewController.swift
//  FaceAnimation_Pytorch
//
//  Created by zhangerbing on 2021/9/16.
//

import UIKit

class MainViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var tableView: UITableView!
    
    private var driving_motion_kps: [[String: Any]]!
    
    private var generator: TorchModule = {
        if let filePath = Bundle.main.path(forResource: "generator", ofType: "ptl"),
           let module = TorchModule(fileAtPath: filePath) {
            return module
        } else {
            fatalError("Cant't find the model file!")
        }
    }()
    
    private var kpDetector: TorchModule = {
        if let filePath = Bundle.main.path(forResource: "kp_detector", ofType: "ptl"),
           let module = TorchModule(fileAtPath: filePath) {
            return module
        } else {
            fatalError("Cant't find the model file!")
        }
    }()
    
    private lazy var testImage: UIImage = {
        if let imagePath = Bundle.main.path(forResource: "male_std", ofType: "jpg") {
            return UIImage(contentsOfFile: imagePath)!
        }
        return UIImage()
    }()
    
    // MARK: - View life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        tableView.tableFooterView = UIView()
        imageView.image = testImage
        
        let driving_kp_name = "myh-389-fps15"
        driving_motion_kps = FileUtils.load(name: driving_kp_name, type: "json") as? [[String: Any]]
        
        logInfo("准备就绪")
    }
}

// MARK: - Pytorch
extension MainViewController {
    private func execute() {
//        guard let buffer = testImage.pixelBuffer(), var resizeBuffer = buffer.resize(to: CGSize(width: 256, height: 256)) else {
//            self.logInfo("加载图片失败")
//            return
//        }
        
        let resizedImage = testImage.resized(to: CGSize(width: 256, height: 256))
        guard var pixelBuffer = resizedImage.normalized(type: .zero_to_one) else {
            self.logInfo("加载图片失败")
            return
        }
        
        let pointer = UnsafeMutableRawPointer(&pixelBuffer)
        
        let w = Int32(resizedImage.size.width)
        let h = Int32(resizedImage.size.height)
        
        var value: [Float] = []
        var jacobian: [Float] = []
        kpDetector.runKpDetect(pointer, with: Int32(w), height: Int32(h)) { values, jacobians in
            value = values.map { $0.floatValue }
            jacobian = jacobians.map { $0.floatValue }
        }
    
//        predictions = []
//        for kp_driving_flat in tqdm(driving_motion_kp):
//
//            # reshape kp['value]: (10,2) -> (1,10,2)
//            val = np.array(kp_driving_flat['value'], dtype=np.float32)
//            val = torch.tensor(val[np.newaxis].astype(np.float32))
//
//            # reshape kp['value]: (1,10,2,2) -> (1,10,2,2)
//            jac = np.array(kp_driving_flat['jacobian'], dtype=np.float32)
//            jac = torch.tensor(jac[np.newaxis].astype(np.float32))
//
//            # make prediction for each frame
//            kp_driving = {'value':val, 'jacobian':jac}
//            res = generator(img, kp_driving, kp_source)
//            predictions.append(res['prediction']) # res['prediction'].shape = (1,3,256,256)
//        print("make animation ... finished.")
            
        autoreleasepool {
            let count = driving_motion_kps.count
            for (index, kp_driving) in driving_motion_kps.enumerated() {
                autoreleasepool {
                    let text = String(format: "生成人脸图像帧,进度:%.2f%%", (Float(index) / Float(count)) * 100.0)
                    print(text)
                    
                    let jac_arr = (kp_driving["jacobian"] as! [[[NSNumber]]]).map { $0.map { $0.map { $0.floatValue } } }
                    let jac = jac_arr.flatMap { $0.flatMap { $0 } }
                    let val_arr = (kp_driving["value"] as! [[NSNumber]]).map { $0.map { $0.floatValue } }
                    let val = val_arr.flatMap { $0 }
                    
                    generator.runGenerator(pointer, with: w, height: h, kp_driving: ["value": value, "jacobian": jacobian], kp_source: ["value": val, "jacobian": jac])                    
                }
            }
        }
        
        
        
        free(pointer)
    }
}

extension MainViewController {
    private func logInfo(_ info: String) {
        let prefix = "输出台:\n\n"
        textView.text = prefix + info
    }
}

// MARK: - UITableViewDelegate && UITableViewDataSource
extension MainViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! MainTableViewCell
        cell.titleLabel.text = "开始"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.row {
        case 0:
            execute()
            logInfo("开始执行...")
        default:
            break
        }
    }
}
