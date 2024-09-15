//
//  PostViewController.swift
//  project-2-lousalvant
//
//  Created by Lou-Michael Salvant on 9/6/24.
//

import UIKit
import PhotosUI
import ParseSwift
import CoreLocation

class PostViewController: UIViewController, CLLocationManagerDelegate {
    
    // Stretch Feature: Location manager to get the user's current location
    let locationManager = CLLocationManager()
    var currentLocation: CLLocation?

    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var captionTextField: UITextField!
    @IBOutlet weak var previewImageView: UIImageView!

    private var pickedImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Stretch Feature: Request location authorization
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    // Stretch Feature: Handle location updates
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
        locationManager.stopUpdatingLocation() // Stop updates to save battery
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location error: \(error.localizedDescription)")
    }

    @IBAction func onPickedImageTapped(_ sender: UIBarButtonItem) {
        // Create a configuration object
        var config = PHPickerConfiguration()

        // Set the filter to only show images as options (i.e. no videos, etc.).
        config.filter = .images

        // Request the original file format. Fastest method as it avoids transcoding.
        config.preferredAssetRepresentationMode = .current

        // Only allow 1 image to be selected at a time.
        config.selectionLimit = 1

        // Instantiate a picker, passing in the configuration.
        let picker = PHPickerViewController(configuration: config)

        // Set the picker delegate so we can receive whatever image the user picks.
        picker.delegate = self

        // Present the picker
        present(picker, animated: true)
    }
    
    @IBAction func onTakePhotoTapped(_ sender: UIBarButtonItem) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                    print("❌📷 Camera not available")
                    return
                }

                // Instantiate the image picker
                let imagePicker = UIImagePickerController()

                // Shows the camera (vs the photo library)
                imagePicker.sourceType = .camera

                // Allows user to edit image within image picker flow (i.e. crop, etc.)
                imagePicker.allowsEditing = true

                // The image picker (camera in this case) will return captured photos via its delegate method.
                imagePicker.delegate = self

                // Present the image picker (camera)
                present(imagePicker, animated: true)
    }
    

    @IBAction func onShareTapped(_ sender: Any) {
        // Dismiss Keyboard
        view.endEditing(true)

        // Unwrap optional pickedImage
        guard let image = pickedImage,
              let imageData = image.jpegData(compressionQuality: 0.1) else {
            return
        }

        // Create a Parse File by providing a name and passing in the image data
        let imageFile = ParseFile(name: "image.jpg", data: imageData)

        // Create Post object
        var post = Post()

        // Set properties
        post.imageFile = imageFile
        post.caption = captionTextField.text

        // Set the user as the current user
        post.user = User.current

        // Stretch Feature: Set the location if available
        if let location = currentLocation {
            post.location = try? ParseGeoPoint(latitude: location.coordinate.latitude,
                                          longitude: location.coordinate.longitude)
        }

        // Save object in background (async)
        post.save { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let post):
                    print("✅ Post Saved! \(post)")
                    
                    // Get the current user
                    if var currentUser = User.current {

                        // Update the `lastPostedDate` property on the user with the current date.
                        currentUser.lastPostedDate = Date()

                        // Save updates to the user (async)
                        currentUser.save { [weak self] result in
                            DispatchQueue.main.async {
                                switch result {
                                case .success(let user):
                                    print("✅ User Saved! \(user)")

                                    // Return to previous view controller
                                    self?.navigationController?.popViewController(animated: true)

                                    // After the post is successfully saved, reload the feed
                                    NotificationCenter.default.post(name: Notification.Name("postSuccess"), object: nil)


                                case .failure(let error):
                                    // Show the alert on the main thread
                                    self?.showAlert(description: error.localizedDescription)
                                }
                            }
                        }
                    }

                case .failure(let error):
                    // Show the alert on the main thread
                    DispatchQueue.main.async {
                        self?.showAlert(description: error.localizedDescription)
                    }
                }
            }
        }
    }


    @IBAction func onViewTapped(_ sender: Any) {
        // Dismiss keyboard
        view.endEditing(true)
    }

    private func showAlert(description: String? = nil) {
        let alertController = UIAlertController(title: "Oops...", message: "\(description ?? "Please try again...")", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(action)
        present(alertController, animated: true)
    }
}


extension PostViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        // Dismiss the picker
        picker.dismiss(animated: true)

        // Make sure we have a non-nil item provider
        guard let provider = results.first?.itemProvider,
           // Make sure the provider can load a UIImage
           provider.canLoadObject(ofClass: UIImage.self) else { return }

        // Load a UIImage from the provider
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, error in

           // Make sure we can cast the returned object to a UIImage
           guard let image = object as? UIImage else {

              // ❌ Unable to cast to UIImage
              self?.showAlert()
              return
           }

           // Check for and handle any errors
           if let error = error {
               self?.showAlert(description: error.localizedDescription)
              return
           } else {

              // UI updates (like setting image on image view) should be done on main thread
              DispatchQueue.main.async {

                 // Set image on preview image view
                 self?.previewImageView.image = image

                 // Set image to use when saving post
                 self?.pickedImage = image
              }
           }
        }
    }
    

}

extension PostViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // Delegate method that's called when user finishes picking image (photo library or camera)
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        // Dismiss the image picker
        picker.dismiss(animated: true)

        // Get the edited image from the info dictionary (if `allowsEditing = true` for image picker config).
        // Alternatively, to get the original image, use the `.originalImage` InfoKey instead.
        guard let image = info[.editedImage] as? UIImage else {
            print("❌📷 Unable to get image")
            return
        }

        // Set image on preview image view
        previewImageView.image = image

        // Set image to use when saving post
        pickedImage = image
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // Dismiss the picker if the user cancels
        picker.dismiss(animated: true)
    }
}

