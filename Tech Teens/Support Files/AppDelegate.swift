//
//  AppDelegate.swift
//  Tech Teens
//
//  Created by Finlay Nathan on 4/25/20.
//  Copyright © 2020 Finlay Nathan. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import GoogleSignIn
import FirebaseFirestore

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
        return true
    }
    
    @available(iOS 9.0, *)
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        return GIDSignIn.sharedInstance().handle(url)
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return GIDSignIn.sharedInstance().handle(url)
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        
        if let error = error {
            let alertController = UIAlertController(title: "Error", message: "A sign in error occurred. Please try again later.\n\(error)", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: .default))
            UIApplication.shared.windows.first?.rootViewController?.present(alertController, animated: true)
            return
        }
        
        guard let authentication = user.authentication else { return }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
        
        Auth.auth().signIn(with: credential) { (authResult, error) in
            if let error = error {
                let alertController = UIAlertController(title: "Error", message: "A sign in error occurred. Please try again later.\n\(error)", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Dismiss", style: .default))
                UIApplication.shared.windows.first?.rootViewController?.present(alertController, animated: true)
            } else {
                let email = authResult?.user.email
                let db = Firestore.firestore()

                db.collection("users").document("teens").getDocument { (document, error) in
                    if let document = document, document.exists {
                        
                        let verifiedUsers = document.get("verified") as! [String]
                        if verifiedUsers.contains(email!) {
                            print("Sign In Successful!")
                            let alertController = UIAlertController(title: "Success!", message: "You have successfully signed in. Press the blue button to start helping!", preferredStyle: .alert)
                            alertController.addAction(UIAlertAction(title: "Dismiss", style: .default))
                            UIApplication.shared.windows.first?.rootViewController?.present(alertController, animated: true)
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "load"), object: nil)
                        } else {
                            
                            do { try Auth.auth().signOut() }
                            catch let signOutError as NSError {
                              print ("Error signing out: %@", signOutError)
                            }
                            
                            print("Unverified account, the user was signed out.")
                            
                            let alertController = UIAlertController(title: "Error", message: "Your account is not verified. Press dismiss, then apply to become a Tech Teen below!", preferredStyle: .alert)
                            alertController.addAction(UIAlertAction(title: "Dismiss", style: .default))
                            UIApplication.shared.windows.first?.rootViewController?.present(alertController, animated: true)
                            
                        }
                    } else {
                        print("Document does not exist")
                        do { try Auth.auth().signOut() }
                        catch let signOutError as NSError {
                          print ("Error signing out: %@", signOutError)
                        }
                    }
                }
                
            }
        }
            
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        print("sign out successful")
    }

}

