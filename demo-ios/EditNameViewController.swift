//
//  ViewController.swift
//  demo-ios
//
//  Created by Stan on 8/27/15.
//  Copyright (c) 2015 Ably. All rights reserved.
//

import UIKit
import GradientView
import IHKeyboardAvoiding

class EditNameViewController: UIViewController {

    @IBOutlet weak var nameTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        KeyboardAvoiding.avoidingView = self.view

        let rootView = self.view as! GradientView
        rootView.colors = [UIColor.white, UIColor(white: 0.87, alpha: 1)]
        rootView.locations = [0.2, 0.95]
        rootView.mode = .radial
    }

    override func shouldPerformSegue(withIdentifier identifier: String?, sender: Any?) -> Bool {
        return nameTextField.text != nil && !nameTextField.text!.isEmpty
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.nameTextField.endEditing(true)
        
        let clientId = nameTextField.text
        let chatViewController = segue.destination as! ChatViewController;
        chatViewController.clientId = clientId
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func primaryActionTriggered(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "DefaultSegue", sender: self)
    }
}

