//
//  RightViewController.swift
//  Wheels
//
//  Created by Diego on 11/30/14.
//  Copyright (c) 2014 Diego. All rights reserved.
//

import UIKit

class RightViewController: UIViewController, FBLoginViewDelegate
{
    @IBOutlet weak var fbLoginView: FBLoginView!
    @IBOutlet weak var grabber: UIView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        fbLoginView.delegate = self
        
        //Bug hace que frame.size.height no retorne el valor correcto
        grabber.layer.cornerRadius = 40/2
        grabber.clipsToBounds = true
        
        fbLoginView.layer.cornerRadius = 10
        fbLoginView.clipsToBounds = true
    }
    
    func loginViewShowingLoggedOutUser(loginView: FBLoginView!)
    {
        navigationController?.popToRootViewControllerAnimated(true)
    }    
}
