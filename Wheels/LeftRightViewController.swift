//
//  MainViewController.swift
//  Wheels
//
//  Created by Diego on 11/2/14.
//  Copyright (c) 2014 Diego. All rights reserved.
//

import Foundation

class LeftRightViewController: TTScrollSlidingPagesController, TTSlidingPagesDataSource, TTSliddingPageDelegate, UIScrollViewDelegate
{
    @IBOutlet weak var scrollView: UIScrollView!
    var viewControllers: Array<UIViewController!>!  = nil
    
    private(set) var lastScrollPercentage:CGFloat = 0

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?)
    {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        disableUIPageControl = true
        zoomOutAnimationDisabled = true
        triangleBackgroundColour = UIColor.clearColor()
        
        scrollView.delegate = self
        scrollView.scrollsToTop = false
    }

    required init(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        
        disableUIPageControl = true
        zoomOutAnimationDisabled = true
        triangleBackgroundColour = UIColor.clearColor()
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        viewControllers = [UIViewController]()
        viewControllers.append(storyboard?.instantiateViewControllerWithIdentifier("PostsViewController") as PostsViewController)
        viewControllers.append(storyboard?.instantiateViewControllerWithIdentifier("RightViewController") as RightViewController)
        
        dataSource = self
        delegate = self
    }
    
    func numberOfPagesForSlidingPagesViewController(source: TTScrollSlidingPagesController!) -> Int32
    {
        return 2
    }
    
    func pageForSlidingPagesViewController(source: TTScrollSlidingPagesController!, atIndex index: Int32) -> TTSlidingPage!
    {
        return TTSlidingPage(contentViewController: viewControllers[Int(index)])
    }

    func titleForSlidingPagesViewController(source: TTScrollSlidingPagesController!, atIndex index: Int32) -> TTSlidingPageTitle!
    {
        return TTSlidingPageTitle(headerText: nil)
    }
    
    override func scrollViewDidScroll(scrollView : UIScrollView)
    {
        let controller = viewControllers[Int(getCurrentDisplayedPage())]
        
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
    
    func didScrollToViewAtIndex(index: UInt)
    {
        if index == 1 //RightViewController
        {
            NSNotificationCenter.defaultCenter().postNotificationName("rightViewControllerViewDidAppear", object: nil)
        }
    }
}
