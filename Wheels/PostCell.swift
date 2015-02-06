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
    @IBOutlet weak var leadingSpaceToBackgroundConstraint: NSLayoutConstraint!
    @IBOutlet weak var trailingSpaceToBackgroundConstraint: NSLayoutConstraint!
    
    let heightWithoutTextField:CGFloat = 100
    
    var width: CGFloat
    {
        get
        {
            return UIScreen.mainScreen().bounds.size.width - leadingSpaceToBackgroundConstraint.constant - trailingSpaceToBackgroundConstraint.constant
        }
    }
    
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
    
    override func setHighlighted(highlighted: Bool, animated: Bool)
    {
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            
            if highlighted
            {
                self.background.backgroundColor = UIColor(white: 0.9, alpha: 1)
            }
            else
            {
                self.background.backgroundColor = UIColor.whiteColor()
            }
        }, completion: nil)
    }
}