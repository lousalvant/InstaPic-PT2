//
//  LoginViewController.swift
//  project-2-lousalvant
//
//  Created by Lou-Michael Salvant on 9/6/24.
//

import UIKit
import ParseSwift
import UserNotifications

class LoginViewController: UIViewController {

    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func onLoginTapped(_ sender: Any) {

        // Make sure all fields are non-nil and non-empty
        guard let username = usernameField.text,
              let password = passwordField.text,
              !username.isEmpty,
              !password.isEmpty else {

            showMissingFieldsAlert()
            return
        }

        // Log in the parse user
        User.login(username: username, password: password) { [weak self] result in

            switch result {
            case .success(let user):
                print("✅ Successfully logged in as user: \(user)")

                // Post a notification that the user has successfully logged in
                NotificationCenter.default.post(name: Notification.Name("login"), object: nil)

                // Request notification permissions and schedule reminder
                self?.requestNotificationPermissions()
                self?.schedulePostReminder()

            case .failure(let error):
                self?.showAlert(description: error.localizedDescription)
            }
        }
    }
    
    // Function to request notification permissions
    func requestNotificationPermissions() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            if granted {
                print("✅ Notifications granted")
                // Schedule the reminder if permission is granted
                self?.schedulePostReminder()
            } else if let error = error {
                print("❌ Failed to request notifications: \(error.localizedDescription)")
            } else {
                print("❌ Notifications denied")
            }
        }
    }

    // Function to schedule the reminder notification
    func schedulePostReminder() {
        let center = UNUserNotificationCenter.current()
        
        // Check if notifications are allowed before scheduling
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else {
                print("❌ Notifications are not authorized")
                return
            }

            let content = UNMutableNotificationContent()
            content.title = "Time to Post!"
            content.body = "Don't forget to share a photo with your friends today."
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

            let request = UNNotificationRequest(identifier: "postReminder", content: content, trigger: trigger)

            center.add(request) { error in
                if let error = error {
                    print("❌ Error scheduling notification: \(error.localizedDescription)")
                } else {
                    print("✅ Post reminder notification scheduled")
                }
            }
        }
    }

    private func showAlert(description: String?) {
        let alertController = UIAlertController(title: "Unable to Log in", message: description ?? "Unknown error", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(action)
        present(alertController, animated: true)
    }

    private func showMissingFieldsAlert() {
        let alertController = UIAlertController(title: "Opps...", message: "We need all fields filled out in order to log you in.", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(action)
        present(alertController, animated: true)
    }
}
