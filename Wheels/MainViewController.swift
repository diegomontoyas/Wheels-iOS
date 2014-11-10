//
//  MainViewController.swift
//  Wheels
//
//  Created by Diego on 11/3/14.
//  Copyright (c) 2014 Diego. All rights reserved.
//

import Foundation

class MainViewController:UIViewController, PostsTopBarViewControllerDelegate
{
    @IBOutlet var topBackgroundView: UIToolbar!
    @IBOutlet var topContainer: UIView!
    @IBOutlet var bottomContainer: UIView!
    @IBOutlet var topContainerHeightConstraint: NSLayoutConstraint!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        topBackgroundView.translucent = true
        topBackgroundView.barStyle = UIBarStyle.Default
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        if let postsTopBarViewController = segue.destinationViewController as? PostsTopBarViewController
        {
            postsTopBarViewController.delegate = self
            topContainerHeightConstraint.constant -= postsTopBarViewController.filtersCollectionViewHeight
            bottomContainer.layoutIfNeeded()
            view.layoutIfNeeded()
        }
    }
    
    func postsTopBarViewControllerFiltersSpecified(controller: PostsTopBarViewController)
    {
        view.layoutIfNeeded()
        
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            
            self.topContainerHeightConstraint.constant += controller.filtersCollectionView.frame.height
            self.view.setNeedsUpdateConstraints()
            self.view.layoutIfNeeded()
        })
    }
    
    func postsTopBarViewControllerNoFiltersSpecified(controller: PostsTopBarViewController)
    {
        topContainer.layoutIfNeeded()
        
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            
            self.topContainerHeightConstraint.constant -= controller.filtersCollectionView.frame.height
            self.view.setNeedsUpdateConstraints()
            self.view.layoutIfNeeded()
        })
    }
}