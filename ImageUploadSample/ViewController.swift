//
//  ViewController.swift
//  ImageUploadSample
//
//  Created by Win Than Htike on 11/12/18.
//  Copyright © 2018 PADC. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import SDWebImage

var imagePicker = UIImagePickerController()

class ViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var ivProfile: UIImageView!
    @IBOutlet weak var tfName: UITextField!
    @IBOutlet weak var tfEmail: UITextField!
    @IBOutlet weak var tfPhone: UITextField!
    @IBOutlet weak var tfPassword: UITextField!
    @IBOutlet weak var tfConfirmPassword: UITextField!
    @IBOutlet weak var tvAddress: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tfName.delegate = self
        tfEmail.delegate = self
        tfPhone.delegate = self
        tfPassword.delegate = self
        tfConfirmPassword.delegate = self
        tvAddress.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.addTarget(self, action: #selector(didTapView))
        tapRecognizer.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapRecognizer)
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func didTapView() {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc func keyboardWillChange(notification : Notification) {
        
        guard let keyboardReact = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        
        if notification.name == UIResponder.keyboardWillShowNotification {
//            view.frame.origin.y = -keyboardReact.height
            scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardReact.height, right: 0)
        } else {
//            view.frame.origin.y = 0
            scrollView.contentInset = UIEdgeInsets.zero
            
        }
        
        scrollView.scrollIndicatorInsets = scrollView.contentInset
        
    }

    @IBAction func onClickUploadProfile(_ sender: UIButton) {
        chooseUpload(sender, imagePickerControllerDelegate: self)
    }
    
    @IBAction func onClickRegister(_ sender: UIButton) {
        
    }
    
    func chooseUpload(_ sender: UIButton, imagePickerControllerDelegate: UIImagePickerControllerDelegate & UINavigationControllerDelegate) {
        
        let alert = UIAlertController(title: "Choose Image", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
            self.openCamera(imagePickerControllerDelegate: imagePickerControllerDelegate)
        }))
        
        alert.addAction(UIAlertAction(title: "Gallery", style: .default, handler: { _ in
            self.openGallary(imagePickerControllerDelegate: imagePickerControllerDelegate)
        }))
        
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func openCamera(imagePickerControllerDelegate: UIImagePickerControllerDelegate & UINavigationControllerDelegate)
    {
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePicker.delegate = imagePickerControllerDelegate
            imagePicker.sourceType = UIImagePickerController.SourceType.camera
            imagePicker.allowsEditing = true
            self.present(imagePicker, animated: true)
        } else {
            let alert  = UIAlertController(title: "Warning", message: "You don't have camera", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
    }
    
    func openGallary(imagePickerControllerDelegate: UIImagePickerControllerDelegate & UINavigationControllerDelegate)
    {
        imagePicker.delegate = imagePickerControllerDelegate
        imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
        imagePicker.allowsEditing = true
        imagePicker.modalPresentationStyle = .overFullScreen
        self.present(imagePicker, animated: true)
    }
    
}

extension ViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        self.dismiss(animated: true, completion: nil)
        
        if let pickedImage = info[.editedImage] as? UIImage {
            
            if let imageData = pickedImage.pngData() {
                
                Alamofire.upload(multipartFormData: { (multipartFormData) in
                    multipartFormData.append(imageData, withName: "image",fileName: "\(Date().millisecondsSince1970).png", mimeType: "image/png")
                    
                }, to:"https://phat-kyi.herokuapp.com/public/api/uploadImage", method : .post) { (result) in
                    
                    switch result {
                        
                    case .success(let upload, _, _):
                        
                        upload.uploadProgress(closure: { (progress) in
                            print("Upload Progress: \(progress.fractionCompleted)")
                        })
                        
                        upload.responseJSON { response in
                            
                            let api = response.result.value
                            
                            if let result = api {
                                
                                let json = JSON(result)
                                
                                if json["code"].int ?? 0 == 200 {
                                    
                                    self.ivProfile.sd_setImage(with: URL(string: json["data"].string!), placeholderImage: UIImage(named: "profile-placeholder"))
                                    
                                    print(json["data"].string!)
                                    
                                } else {
                                    print(json["code"])
                                }
                                
                            } else {
                                
                                print(api)
                                
                            }
                            
                        }
                        
                        break
                        
                    case .failure(let error):
                        print(error)
                        break
                        
                    }
                    
                }
                
            } else {
                
            }
            
        } else {
            print("image is null")
        }
        
    } 
    
}

extension Date {
    var millisecondsSince1970:Int {
        return Int((self.timeIntervalSince1970 * 1000.0).rounded())
    }
    
    init(milliseconds:Int) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds / 1000))
    }
}

