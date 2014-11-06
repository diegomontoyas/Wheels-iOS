//
//  PageViewController.swift
//  Wheels
//
//  Created by Diego on 11/2/14.
//  Copyright (c) 2014 Diego. All rights reserved.
//

import Foundation

protocol MainPageViewControllerDelegate: class
{
    
}

class MainPageViewController: UIPageViewController,UIPageViewControllerDelegate, UIPageViewControllerDataSource, UIGestureRecognizerDelegate, UIScrollViewDelegate
{
    var scrollViewPanGestureRecognzier = UIPanGestureRecognizer()
    var originalPanGestureRecognizer: UIPanGestureRecognizer!
    
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
        
        let initialViewController = storyboard?.instantiateViewControllerWithIdentifier("PostsViewController") as UIViewController
        setViewControllers([initialViewController], direction: UIPageViewControllerNavigationDirection.Forward, animated: false, completion: nil)        
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController?
    {
        if viewController is PostViewController
        {
            return storyboard?.instantiateViewControllerWithIdentifier("PostsViewController") as? PostsViewController
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
            return storyboard?.instantiateViewControllerWithIdentifier("PostViewController") as? PostViewController
        }
        else
        {
            return nil
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView)
    {
        let percentage = scrollView.contentOffset.x / scrollView.contentSize.width
        
        println(percentage)
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