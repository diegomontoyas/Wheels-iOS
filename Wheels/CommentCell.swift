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
    let heightWithoutTextField:CGFloat = 25

    @IBOutlet var textField: UITextView!
    @IBOutlet var background: UIView!
}