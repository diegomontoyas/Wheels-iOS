//
//  FilterCell.swift
//  Wheels
//
//  Created by Diego on 10/31/14.
//  Copyright (c) 2014 Diego. All rights reserved.
//

import Foundation

protocol FilterCellDelegate
{
    
}

class FilterCell: UICollectionViewCell
{
    @IBOutlet var textVIew: UITextView!
    @IBOutlet var label: UILabel!
    @IBOutlet var button: UIButton!
    
    weak var delegate: AnyObject?
    
    @IBAction func buttonPressed(sender: AnyObject)
    {
        
    }

}
