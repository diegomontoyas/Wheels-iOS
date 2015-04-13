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
    private(set) var scrollViewPanGestureRecognzier = UIPanGestureRecognizer()
    
    private(set) var scrollView: UIScrollView!
    
    private(set) var lastScrollPercentage:CGFloat = 0
    
    private var postsViewController: PostsViewController!
    private var rightViewController: RightViewController!
    
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
                scrollView.scrollsToTop = false
                self.scrollView = scrollView
            }
        }
        
        dataSource = self
        delegate = self
        
        postsViewController = storyboard?.instantiateViewControllerWithIdentifier("PostsViewController") as! PostsViewController
       
        rightViewController = storyboard?.instantiateViewControllerWithIdentifier("RightViewController") as? RightViewController!
        
        setViewControllers([postsViewController], direction: UIPageViewControllerNavigationDirection.Forward, animated: false, completion: nil)
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController?
    {
        if viewController is RightViewController
        {
            return postsViewController
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
            return rightViewController
        }
        else
        {
            return nil
        }
    }
    
    func scrollViewDidScroll(scrollView : UIScrollView)
    {
        let controller = viewControllers.last as! UIViewController
        
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
}