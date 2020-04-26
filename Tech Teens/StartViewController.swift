//
//  StartViewController.swift
//  Tech Teens
//
//  Created by Finlay Nathan on 4/25/20.
//  Copyright © 2020 Finlay Nathan. All rights reserved.
//

import UIKit
import FirebaseAuth
import GoogleSignIn
import Firebase
import SafariServices

class StartViewController: UITableViewController, SFSafariViewControllerDelegate {
    
    var queue = [String]()
    var assisted = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if Auth.auth().currentUser == nil {
            Auth.auth().signInAnonymously() { (authResult, error) in
                if error != nil {
                    let alertController = UIAlertController(title: "Error", message: "An error occured validating your anonymous sign in request. Your device may be offline.", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Dismiss", style: .default))
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(loadList), name: NSNotification.Name(rawValue: "load"), object: nil)
        
        Firestore.firestore().collection("users").document("guests").addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot else {
                print("Error fetching document: \(error!)")
                return
            }
            self.queue = document.get("list") as! [String]
            self.assisted = document.get("assisted") as! [String]
            self.tableView.reloadData()
        }
        
    }

    @objc func loadList() {
        self.tableView.reloadData()
    }
    
    func createCell(title: String, tap: Bool, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "defaultCell", for: indexPath)
        cell.textLabel?.text = title
        if tap == true {
            cell.selectionStyle = .default
            cell.accessoryType = .disclosureIndicator
        } else {
            cell.selectionStyle = .none
            cell.accessoryType = .none
        }
        
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = .byWordWrapping
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            
            self.tableView.deselectRow(at: self.tableView.indexPathForSelectedRow!, animated: true)
            if Auth.auth().currentUser?.email != nil {
                
                if self.queue.isEmpty != true {
                    
                    let alertController = UIAlertController(title: "Connect as Tech Teen", message:
                        "By pressing Accept, you agree to our code of conduct, terms of service, and privacy policy. Be respectful, patient, and helpful. Abuse of this service will result in a ban.", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Decline", style: .cancel))
                    alertController.addAction(UIAlertAction(title: "Accept", style: .default, handler: { action in
                        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
                        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "VideoController") as! VideoChatViewController
                        nextViewController.modalPresentationStyle = .fullScreen
                        
                        var newAssisted = self.assisted
                        newAssisted.append(self.queue[0])
                        Firestore.firestore().collection("users").document("guests").setData([ "assisted": newAssisted ], merge: true)
                        
                        nextViewController.channelId = self.queue[0]
                        self.queue.remove(at: 0)
                        Firestore.firestore().collection("users").document("guests").setData([ "list": self.queue ], merge: true)
                        nextViewController.assisting = true
                        self.present(nextViewController, animated: true, completion: nil)
                    }))
                    self.present(alertController, animated: true, completion: nil)
                    
                }
                
            } else {
                
                if Auth.auth().currentUser == nil {
                    Auth.auth().signInAnonymously() { (authResult, error) in
                        if error != nil {
                            let alertController = UIAlertController(title: "Error", message: "An error occured validating your anonymous sign in request. Your device may be offline.", preferredStyle: .alert)
                            alertController.addAction(UIAlertAction(title: "Dismiss", style: .default))
                            self.present(alertController, animated: true, completion: nil)
                        }
                    }
                }
                
                let alertController = UIAlertController(title: "Connect with Tech Teen", message:
                    "By pressing Accept, you will be placed in a queue to video call with the next available Tech Teen for support. Be respectful and patient. Abuse of this service will result in a ban.", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Decline", style: .cancel))
                alertController.addAction(UIAlertAction(title: "Accept", style: .default, handler: { action in
                    
                    let uid = Auth.auth().currentUser?.uid
                    
                    let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
                    let vc = storyBoard.instantiateViewController(withIdentifier: "VideoController") as! VideoChatViewController
                    vc.modalPresentationStyle = .fullScreen
                    
                    if self.queue.contains(uid!) == false {
                        var newQueue = self.queue
                        newQueue.append(uid!)
                        Firestore.firestore().collection("users").document("guests").setData([ "list": newQueue ], merge: true)
                    }
                    
                    vc.channelId = uid
                    self.present(vc, animated: true, completion: nil)
                    
                }))
                self.present(alertController, animated: true, completion: nil)
            }
            
        } else if indexPath.section == 1 {
            
            
            if indexPath.row == 1 {
                self.tableView.deselectRow(at: self.tableView.indexPathForSelectedRow!, animated: true)
                
                if Auth.auth().currentUser?.email == nil {
                    do {
                        try Auth.auth().signOut()
                        self.tableView.reloadData()
                    }
                    catch let signOutError as NSError {
                        print ("Error signing out: %@", signOutError)
                    }
                    GIDSignIn.sharedInstance()?.presentingViewController = self
                    GIDSignIn.sharedInstance().signIn()
                    self.tableView.reloadData()
                } else {
                    do {
                        try Auth.auth().signOut()
                        self.tableView.reloadData()
                    }
                    catch let signOutError as NSError {
                        print ("Error signing out: %@", signOutError)
                    }
                }
                
            } else if indexPath.row == 2 {
                    let svc = SFSafariViewController(url: NSURL(string: "https://forms.gle/uKs5GKJ2iyWCNWoh7")! as URL)
                    svc.delegate = self
                    self.present(svc, animated: true, completion: nil)
            } else if indexPath.row == 3 {
                let svc = SFSafariViewController(url: NSURL(string: "https://github.com/finlayjn/Virtual-Tech-Teens/blob/master/TERMS.md")! as URL)
                svc.delegate = self
                self.present(svc, animated: true, completion: nil)
            }
            
            
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "joinCell", for: indexPath)
            
            if Auth.auth().currentUser?.email != nil {
                cell.textLabel?.text = "Tap here to connect with the next support request in the queue (\(String(self.queue.count)))"
            } else {
                cell.textLabel?.text = "Tap here to be connected with a certified Tech Teen via video"
            }
            return cell
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                if Auth.auth().currentUser?.email != nil {
                    return createCell(title: "Thank you for being a Tech Teen! Remember to be respectful, patient, and helpful when answering support requests. Press the button above when the queue is greater than 0.", tap: false, indexPath: indexPath)
                } else {
                    return createCell(title: "When you press the button above, you will be placed in a queue to be connected with the next available Virtual Tech Teen.", tap: false, indexPath: indexPath)
                }
            } else if indexPath.row == 1 {
                if Auth.auth().currentUser?.email != nil {
                    return createCell(title: "Logout of Virtual Tech Teens", tap: true, indexPath: indexPath)
                } else {
                    return createCell(title: "Login as a Virtual Tech Teen", tap: true, indexPath: indexPath)
                }
            } else if indexPath.row == 2 {
                return createCell(title: "Become a Virtual Tech Teen", tap: true, indexPath: indexPath)
            } else if indexPath.row == 3 {
                return createCell(title: "Code of Conduct, Terms, & Privacy", tap: true, indexPath: indexPath)
            }
        }

        return createCell(title: "error", tap: false, indexPath: indexPath)
        
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 { return "Start a call" }
        else if section == 1 { return "How it works" }
        else { return "Error" }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 1 { return "Virtual Tech Teens (v1.0 beta)\n\nDeveloped with ❤️ by\nFinlay Nathan\nJessica Golden\nEthan Hopkins\nHenry Marks" }
        else { return nil }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int { return 2 }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 { return 4 }
        else { return 1 }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 { return 90.0 }
        else { return UITableView.automaticDimension }
        
    }
}
