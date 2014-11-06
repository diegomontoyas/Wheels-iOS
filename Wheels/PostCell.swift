//
//  CeldaPost.swift
//  Wheels
//
//  Created by Diego on 10/23/14.
//  Copyright (c) 2014 Diego. All rights reserved.
//

import UIKit

class PostCell: UITableViewCell
{
    @IBOutlet var label: UILabel!
    @IBOutlet var textField: UITextView!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var background: UIView!
    @IBOutlet var fullCarBanner: UILabel!
    @IBOutlet weak var photoImageView: UIImageView!
    
    var full:Bool = false
    {
        didSet
        {
            if full
            {
                fullCarBanner.hidden = false
            }
            else
            {
                fullCarBanner.hidden = true
            }
        }
    }
}