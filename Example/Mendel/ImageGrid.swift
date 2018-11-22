//
//  ImageGrid.swift
//  Mendel_Example
//
//  Created by Patrick Niemeyer on 11/21/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import UIKit

class ImageGrid: UIView
{
    var views = [UIImageView]()
    let size: Int
    
    init(size: Int) {
        self.size = size
        super.init(frame: CGRect.zero)
        
        for _ in 0..<size*size {
            UIImageView().do {
                self.addSubview($0)
                views.append($0)
            }
        }
    }
    
    override public func layoutSubviews()
    {
        super.layoutSubviews()
        
        let pad: CGFloat = 12.0
        let w = (bounds.width - 2*pad) / CGFloat(size)
        let h = w
        for i in 0 ..< size {
            for j in 0 ..< size {
                views[j*size + i].do {
                    $0.frame = CGRect(x: CGFloat(i)*w+pad, y: CGFloat(j)*h+pad, width: w, height: h)
                }
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
