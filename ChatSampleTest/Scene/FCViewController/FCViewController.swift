//
//  FCViewModel.swift
//  ChatSampleTest
//
//  Created by tanaz on 5/20/1399 AP.
//  Copyright © 1399 ChatSampleTest. All rights reserved.
//

import Photos
import UIKit

import Firebase


@objc(FCViewController)
class FCViewController: UIViewController,
    UITextFieldDelegate, UINavigationControllerDelegate {

  // Instance variables
  @IBOutlet weak var textField: UITextField!
  @IBOutlet weak var sendButton: UIButton!
  var messages: [DataSnapshot] = []
  var msglength: NSNumber = 100

  var storageRef: StorageReference!
  private var viewModel: FCViewModel!

  @IBOutlet weak var clientTable: UITableView!
    
  override func viewDidLoad() {
    super.viewDidLoad()
    viewModel = FCViewModel(self)
    clientTable.register(UINib(nibName: "ClientTableViewCell", bundle: .main), forCellReuseIdentifier: "clientCell")
    viewModel.configureDatabase()
    configureStorage()

  }

  deinit {
    if let refHandle = viewModel._refHandle {
        self.viewModel.ref.child("messages").removeObserver(withHandle: refHandle)
    }
  }
    
    func updateTableviewByDatabase(_ snapshot:DataSnapshot) {
        messages.append(snapshot)
        clientTable.insertRows(at: [IndexPath(row: messages.count-1, section: 0)], with: .automatic)
    }

    func configureStorage() {
        storageRef = Storage.storage().reference()

    }
  @IBAction func didSendMessage(_ sender: UIButton) {
    _ = textFieldShouldReturn(textField)
  }

  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    guard let text = textField.text else { return true }

    let newLength = text.utf16.count + string.utf16.count - range.length
    return newLength <= self.msglength.intValue // Bool
  }

  // UITextViewDelegate protocol methods
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    guard let text = textField.text else { return true }
    textField.text = ""
    view.endEditing(true)
    let data = [Constants.MessageFields.text: text]
    sendMessage(withData: data)
    return true
  }

  func sendMessage(withData data: [String: String]) {
    if data.values.first?.isEmpty ?? false {
        return
    }
    var mdata = data
    mdata[Constants.MessageFields.name] = Auth.auth().currentUser?.displayName
    if let photoURL = Auth.auth().currentUser?.photoURL {
      mdata[Constants.MessageFields.photoURL] = photoURL.absoluteString
    }
    // Push data to Firebase Database
    self.viewModel.ref.child("messages").childByAutoId().setValue(mdata)
  }

  // MARK: - Image Picker

  @IBAction func didTapAddPhoto(_ sender: AnyObject) {
    let picker = UIImagePickerController()
    picker.delegate = self
    if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
      picker.sourceType = UIImagePickerController.SourceType.camera
    } else {
      picker.sourceType = UIImagePickerController.SourceType.photoLibrary
    }

    present(picker, animated: true, completion:nil)
  }



  @IBAction func signOut(_ sender: UIButton) {
    
    let firebaseAuth = Auth.auth()
    do {
      try firebaseAuth.signOut()
        navigationController?.popViewController(animated: true)
    } catch let signOutError as NSError {
      print ("Error signing out: \(signOutError.localizedDescription)")
    }
  }

  func showAlert(withTitle title: String, message: String) {
    DispatchQueue.main.async {
        let alert = UIAlertController(title: title,
            message: message, preferredStyle: .alert)
        let dismissAction = UIAlertAction(title: "Dismiss", style: .destructive, handler: nil)
        alert.addAction(dismissAction)
        self.present(alert, animated: true, completion: nil)
    }
  }

}
// MARK: - Image Picker Delegate
extension FCViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
          picker.dismiss(animated: true, completion:nil)
          guard let uid = Auth.auth().currentUser?.uid else { return }

          // if it's a photo from the library, not an image from the camera
      if #available(iOS 8.0, *), let referenceURL = info[UIImagePickerController.InfoKey.referenceURL] as? URL {
            let assets = PHAsset.fetchAssets(withALAssetURLs: [referenceURL], options: nil)
            let asset = assets.firstObject
            asset?.requestContentEditingInput(with: nil, completionHandler: { [weak self] (contentEditingInput, info) in
              let imageFile = contentEditingInput?.fullSizeImageURL
              let filePath = "\(uid)/\(Int(Date.timeIntervalSinceReferenceDate * 1000))/\((referenceURL as AnyObject).lastPathComponent!)"
              guard let strongSelf = self else { return }
              strongSelf.storageRef.child(filePath)
                .putFile(from: imageFile!, metadata: nil) { (metadata, error) in
                  if let error = error {
                    let nsError = error as NSError
                    print("Error uploading: \(nsError.localizedDescription)")
                    return
                  }
                  strongSelf.sendMessage(withData: [Constants.MessageFields.imageURL: strongSelf.storageRef.child((metadata?.path)!).description])
                }
            })
          } else {
          guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
          let imageData = image.jpegData(compressionQuality: 0.8)
            let imagePath = "\(uid)/\(Int(Date.timeIntervalSinceReferenceDate * 1000)).jpg"
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            self.storageRef.child(imagePath)
              .putData(imageData!, metadata: metadata) { [weak self] (metadata, error) in
                if let error = error {
                  print("Error uploading: \(error)")
                  return
                }
                guard let strongSelf = self else { return }
                strongSelf.sendMessage(withData: [Constants.MessageFields.imageURL: strongSelf.storageRef.child((metadata?.path)!).description])
            }
          }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      picker.dismiss(animated: true, completion:nil)
    }
}
// MARK: - TableView Delegate and DataSource
extension FCViewController:  UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      // Dequeue cell
      let cell = self.clientTable.dequeueReusableCell(withIdentifier: "clientCell", for: indexPath) as! ClientTableViewCell
      // Unpack message from Firebase DataSnapshot
      let messageSnapshot: DataSnapshot! = self.messages[indexPath.row]
      guard let message = messageSnapshot.value as? [String:String] else { return cell }
      let name = message[Constants.MessageFields.name] ?? ""
      let txt = message[Constants.MessageFields.text] ?? ""
      if let imageURL = message[Constants.MessageFields.imageURL] {
        if imageURL.hasPrefix("gs://") {
          Storage.storage().reference(forURL: imageURL).getData(maxSize: INT64_MAX) {(data, error) in
            if let error = error {
              print("Error downloading: \(error)")
              return
            }
            DispatchQueue.main.async {
              cell.config(image: UIImage.init(data: data!) ?? UIImage(), txt: name + ":" + txt)
              cell.setNeedsLayout()
            }
          }
        } else if let URL = URL(string: imageURL), let data = try? Data(contentsOf: URL) {
          cell.config(image: UIImage.init(data: data) ?? UIImage(), txt: name + ":" + txt)

        }
      } else {
        let text = message[Constants.MessageFields.text] ?? ""
        let txt = name + ": " + txt
          let img = UIImage(named: "ic_account_circle") ?? UIImage()
          cell.config(image: img, txt: txt)
        if let photoURL = message[Constants.MessageFields.photoURL], let URL = URL(string: photoURL),
            let data = try? Data(contentsOf: URL) {
          let img = UIImage(data: data)
          cell.config(image: img ?? UIImage(), txt: name + ": " + text)
          
        }
      }
      return cell
    }
}
