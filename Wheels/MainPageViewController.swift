//
//  PageViewController.swift
//  Wheels
//
//  Created by Diego on 11/2/14.
//  Copyright (c) 2014 Diego. All rights reserved.
//

import Foundation

class MainPageViewController: UIPageViewController,UIPageViewControllerDelegate, UIPageViewControllerDataSource, UIGestureRecognizerDelegate, UIScrollViewDelegate
{
    var scrollViewPanGestureRecognzier = UIPanGestureRecognizer()
    var originalPanGestureRecognizer: UIPanGestureRecognizer!
    
    var scrollView: UIScrollView!
    
    var lastScrollPercentage:CGFloat = 0
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        for view in self.view.subviews
        {
            if let scrollView = view as? UIScrollView
            {
                scrollView.alwaysBounceHorizontal = true
                scrollView.alwaysBounceVertical = false
                scrollView.delegate = self
                self.scrollView = scrollView
                
                for gestureRecognizer in scrollView.gestureRecognizers!
                {
                    if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer
                    {
                        originalPanGestureRecognizer = panGestureRecognizer
                    }
                }
                
                scrollViewPanGestureRecognzier.delegate = self
                //scrollView.addGestureRecognizer(scrollViewPanGestureRecognzier)
            }
        }
        
        dataSource = self
        delegate = self
        
        let initialViewController = storyboard?.instantiateViewControllerWithIdentifier("PostsViewController") as PostsViewController
        setViewControllers([initialViewController], direction: UIPageViewControllerNavigationDirection.Forward, animated: false, completion: nil)
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController?
    {
        if viewController is PostViewController
        {
            let controller = storyboard?.instantiateViewControllerWithIdentifier("PostsViewController") as? PostsViewController
            return controller
        }
        else
        {
            return nil
        }
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController?
    {
        if viewController is PostsViewController
        {
            let controller = storyboard?.instantiateViewControllerWithIdentifier("PostViewController") as? PostViewController
            return controller
        }
        else
        {
            return nil
        }
    }
    
    func scrollViewDidScroll(scrollView : UIScrollView)
    {
        let controller = viewControllers.last as UIViewController
        
        var percentage: CGFloat = 0
        
        if scrollView.contentOffset.x >= view.frame.size.width && scrollView.contentOffset.x < view.frame.size.width*2
        {
            percentage = ((scrollView.contentOffset.x-view.frame.size.width) / (view.frame.size.width*2))*2
        }
        else if scrollView.contentOffset.x >= 0 && scrollView.contentOffset.x <= view.frame.size.width
        {
            percentage = (scrollView.contentOffset.x / view.frame.size.width)
        }
        
        if abs(percentage-lastScrollPercentage) < 0.5
        {
            lastScrollPercentage = percentage
            
            let broadCastDictionary = ["controller":controller, "percentage":percentage]
            NSNotificationCenter.defaultCenter().postNotificationName("pageViewControllerDidScroll", object: nil, userInfo: broadCastDictionary)
        }
    }
    
    func controllerGrabberPressed(controller: UIViewController)
    {
        /*if controller is PostsViewController
        {
            scrollView.setContentOffset(CGPointMake(50,0), animated: true)
            scrollView.setContentOffset(CGPointMake(-50,0), animated: true)
        }
        else if controller is PostViewController
        {
            
        }*/
    }
    
    let grabberWidth:CGFloat = 40
    let distanceToGrabberBottomFromBottomOfScreen:CGFloat = 70
    
    /*func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool
    {
        if gestureRecognizer === scrollViewPanGestureRecognzier
        {
            let locationInView = gestureRecognizer.locationInView(view)
            
            let y = locationInView.y
            let x = locationInView.x
            
            let screenBounds = UIScreen.mainScreen().bounds
            
            if y > screenBounds.size.height-distanceToGrabberBottomFromBottomOfScreen-grabberWidth
                && y < screenBounds.size.height-distanceToGrabberBottomFromBottomOfScreen
            {
                if viewControllers.first is PostsViewController && (x > screenBounds.size.width-grabberWidth) && (x < screenBounds.size.width)
                {
                    return false
                }
                else if viewControllers.first is PostViewController && (x > 0) && (x < grabberWidth)
                {
                    return false
                }
            }
            else
            {
                return true
            }
        }
        return true
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool
    {
        return false
    }*/
}