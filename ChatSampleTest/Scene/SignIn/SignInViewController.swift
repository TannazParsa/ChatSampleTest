//
//  ViewController.swift
//  TestProject
//
//  Created by tanaz on 5/19/1399 AP.
//  Copyright © 1399 Test. All rights reserved.
//

import UIKit

import Firebase
import GoogleSignIn

class SignInViewController: UIViewController {
  @IBOutlet weak var signInButton: GIDSignInButton!
  var handle: AuthStateDidChangeListenerHandle?

  override func viewDidLoad() {
    super.viewDidLoad()
    GIDSignIn.sharedInstance()?.presentingViewController = self
    GIDSignIn.sharedInstance().restorePreviousSignIn()
    handle = Auth.auth().addStateDidChangeListener() { (auth, user) in
      if user != nil {
        MeasurementHelper.sendLoginEvent()
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let chatVC = storyboard.instantiateViewController(withIdentifier: "FCViewController") as! FCViewController
        self.navigationController?.pushViewController(chatVC, animated: true)
      }
    }
  }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
    }

  deinit {
    if let handle = handle {
      Auth.auth().removeStateDidChangeListener(handle)
    }
  }
}
