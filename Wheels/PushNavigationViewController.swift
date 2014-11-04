//
//  MainViewController.swift
//  Wheels
//
//  Created by Diego on 11/2/14.
//  Copyright (c) 2014 Diego. All rights reserved.
//

import Foundation

class PushNavigationViewController: UIViewController, UIGestureRecognizerDelegate
{
    var panGestureRecognzier = UIPanGestureRecognizer()
    
    var leftViewController:UIViewController! = nil
    var rightViewController:UIViewController! = nil
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        panGestureRecognzier.delegate = self
        panGestureRecognzier.addTarget(self, action: Selector("handlePan:"))
        view.addGestureRecognizer(panGestureRecognzier)
        
        leftViewController = storyboard?.instantiateViewControllerWithIdentifier("PostsViewController") as UIViewController
        rightViewController = storyboard?.instantiateViewControllerWithIdentifier("PostViewController") as UIViewController
        
        rightViewController.view.frame.origin = CGPointMake(UIScreen.mainScreen().bounds.width, 0)

        addChildViewController(leftViewController)
        view.addSubview(leftViewController.view)
        leftViewController.didMoveToParentViewController(self)
        
        addChildViewController(rightViewController)
        view.addSubview(rightViewController.view)
        rightViewController.didMoveToParentViewController(self)
    }
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool
    {
        if gestureRecognizer === panGestureRecognzier
        {
            let locationInView = gestureRecognizer.locationInView(view)
            
            let y = locationInView.y
            let x = locationInView.x
            
            if x > 100 && x < 320 && y > 400
            {
                return true
            }
            else
            {
                return false
            }
        }
        return false
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool
    {
        return false
    }
    
    func handlePan(gestureRecognizer:UIPanGestureRecognizer)
    {
        let translation = gestureRecognizer.translationInView(view)
        
        rightViewController.view.frame.origin = CGPointMake(rightViewController.view.frame.origin.x + translation.x, 0)
        leftViewController.view.frame.origin = CGPointMake(leftViewController.view.frame.origin.x + translation.x, 0)
        
        gestureRecognizer.setTranslation(CGPointMake(0, 0), inView:view)
    }
}
