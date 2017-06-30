//
//  UIColor.swift
//  HelloAR
//
//  Created by Minxin Guo on 6/30/17.
//  Copyright © 2017 Minxin Guo. All rights reserved.
//

import UIKit

extension UIColor {
    static func random() -> UIColor {
        let r = CGFloat(drand48())
        let g = CGFloat(drand48())
        let b = CGFloat(drand48())
        return UIColor(red: r, green: g, blue: b, alpha: 1.0)
    }
}
