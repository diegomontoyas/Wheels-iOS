//
//  LoginViewController.swift
//  Wheels
//
//  Created by Diego on 10/30/14.
//  Copyright (c) 2014 Diego. All rights reserved.
//

import Foundation

class LoginViewController: UIViewController, FBLoginViewDelegate
{
    @IBOutlet var fbLoginView : FBLoginView!
    var readPermissions = ["user_groups"]

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        fbLoginView.delegate = self
        fbLoginView.readPermissions = readPermissions
    }
    
    override func viewDidAppear(animated: Bool)
    {

    }
    
    // Facebook Delegate Methods
    
    func loginViewShowingLoggedInUser(loginView : FBLoginView!)
    {
        println("User Logged In")
        
        transitionToPostsViewController()
    }
    
    func loginViewFetchedUserInfo(loginView : FBLoginView!, user: FBGraphUser)
    {
        println("User: \(user)")
        println("User ID: \(user.objectID)")
        println("User Name: \(user.name)")
    }
    
    func loginViewShowingLoggedOutUser(loginView : FBLoginView!)
    {
        println("User Logged Out")
    }
    
    func loginView(loginView : FBLoginView!, handleError:NSError)
    {
        println("Error: \(handleError.localizedDescription)")
    }

    func transitionToPostsViewController()
    {
        var viewController = storyboard?.instantiateViewControllerWithIdentifier("MainViewController") as MainViewController
        navigationController?.pushViewController(viewController, animated: true)
    }
}