//
//  CeldaPost.swift
//  Wheels
//
//  Created by Diego on 10/23/14.
//  Copyright (c) 2014 Diego. All rights reserved.
//

import UIKit

class PostCell: UITableViewCell, UITextFieldDelegate
{
    @IBOutlet var label: UILabel!
    @IBOutlet var textField: UITextView!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var background: UIView!
    @IBOutlet var backBorderView: UIView!
    @IBOutlet var contentBackground: UIView!
    @IBOutlet var fullCarBanner: UILabel!
    @IBOutlet weak var photoImageView: UIImageView!
    
    @IBOutlet var photoWidthConstraint: NSLayoutConstraint!
    @IBOutlet var photoHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet var spaceBetweenPhotoAndTimeLabelConstraint: NSLayoutConstraint!
    @IBOutlet var spaceBetweenPhotoAndLabelConstraint: NSLayoutConstraint!
    
    let heightWithoutTextField:CGFloat = 90
    
    var full:Bool = false
    {
        didSet
        {
            if full
            {
                fullCarBanner.clipsToBounds = true
                fullCarBanner.layer.cornerRadius = 5
                fullCarBanner.hidden = false
            }
            else
            {
                fullCarBanner.hidden = true
            }
        }
    }
}