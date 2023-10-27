//
//  FirstViewController.swift
//  IMU Data SB
//
//  Created by Lea Hering on 15.01.23.
//

import UIKit

class FirstViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet private var textfield_height : UITextField!
    @IBOutlet private var label_infos : UILabel!
    @IBOutlet private var button_gotoquery : UIButton!
    
    @IBOutlet var firstView : UIView!
    
    var height = 0
    var weight = 0
    /// bioSex: -1 nothing chosen, 0: female, 1: male, 2: other
    var bioSex = 0
    var bioSex_label = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textfield_height.delegate = self
        textfield_height.tag = 1

        textfield_height.text = ""
        textfield_height.placeholder = "Enter height"
        
        hideKeyboardWhenTappedAround()
    }
    

    
    
    @IBAction func buttonSwitchViewClicked(_ sender: UIButton)
    {
        let height_input = Int(textfield_height.text ?? "") ?? 0
        
        if height_input > 0 {  self.height = height_input  }
        if self.height > 0
        {
            let secondController = self.storyboard!.instantiateViewController(withIdentifier: "second_view") as! MainViewController
            secondController.setHeight(height: self.height)
            self.present(secondController, animated: true)
        }
    }

}

extension FirstViewController
{
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboardView))
        //tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboardView() {
        view.endEditing(true)
    }
}
extension FirstViewController
{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
    //Check if there is any other text-field in the view whose tag is +1 greater than the current text-field on which the return key was pressed. If yes → then move the cursor to that next text-field. If No → Dismiss the keyboard
        if let nextField = self.view.viewWithTag(textField.tag + 1) as? UITextField
        {  nextField.becomeFirstResponder()  }
        else {  textField.resignFirstResponder()  }
        return false
    }
}
