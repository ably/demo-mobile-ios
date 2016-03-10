//
//  ViewController.swift
//  demo-ios
//
//  Created by Stan on 8/27/15.
//  Copyright (c) 2015 Ably. All rights reserved.
//

import UIKit

class EditNameViewController: UIViewController {

    @IBOutlet weak var nameTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool {
        return nameTextField.text != nil && !nameTextField.text!.isEmpty
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let clientId = nameTextField.text
        let chatViewController = segue.destinationViewController as! ChatViewController;
        
        // JSQMessagesViewController requires properly set senderId and senderDisplayName
        chatViewController.senderId = clientId
        chatViewController.senderDisplayName = clientId
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

