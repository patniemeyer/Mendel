//
//  ViewController.swift
//  genetic
//
//  Created by Saniul Ahmed on 22/12/2014.
//  Copyright (c) 2014 Saniul Ahmed. All rights reserved.
//

import UIKit

class ImageMatchingViewController: UIViewController {
    
    @IBOutlet var referenceImageView: UIImageView!
    @IBOutlet var bestIndividualImageView: UIImageView!
    @IBOutlet weak var iterationLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    
    var lab = ImageMatchingLab()
    
    let url = Bundle.main.url(forResource: "mona-lisa", withExtension: "jpg")!
    
    let image = UIImage(named: "mona-lisa.jpg")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.referenceImageView.image = image
        tests()
    }
    
    @IBAction func start(sender: UIButton) {
        self.lab.stop()
        
        self.lab = ImageMatchingLab()
        
        self.lab.referenceImageURL = url
        self.lab.outputImageSize = image?.size
        
        self.lab.output = { image, iter in
            DispatchQueue.main.async {
                self.bestIndividualImageView.image = UIImage(cgImage: image)
                self.iterationLabel.text = "\(iter)"
                self.iterationLabel.text = "\(iter)"
            }
        }
        
        DispatchQueue.global().async { () -> Void in
            self.lab.doScience()
        }
    }
    
    func tests() {
        
    }
}

