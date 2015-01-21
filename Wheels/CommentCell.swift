//
//  CommentCell.swift
//  Wheels
//
//  Created by Diego on 11/8/14.
//  Copyright (c) 2014 Diego. All rights reserved.
//

import Foundation

class CommentCell: UITableViewCell, UITextFieldDelegate
{
    let heightWithoutTextField:CGFloat = 15
    @IBOutlet weak var leadingSpaceToBackgroundConstraint: NSLayoutConstraint!
    @IBOutlet weak var trailingSpaceToBackgroundConstraint: NSLayoutConstraint!
    
    @IBOutlet var textField: UITextView!
    @IBOutlet var background: UIView!
    
    var width: CGFloat
    {
        get
        {
            return UIScreen.mainScreen().bounds.size.width - leadingSpaceToBackgroundConstraint.constant - trailingSpaceToBackgroundConstraint.constant
        }
    }
}