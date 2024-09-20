//
//  SceneDelegate.swift
//  project-2-lousalvant
//
//  Created by Lou-Michael Salvant on 9/6/24.
//

import UIKit
import UserNotifications

class SceneDelegate: UIResponder, UIWindowSceneDelegate, UNUserNotificationCenterDelegate {

    private enum Constants {
        static let loginNavigationControllerIdentifier = "LoginNavigationController"
        static let feedNavigationControllerIdentifier = "FeedNavigationController"
        static let storyboardIdentifier = "Main"
    }

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }
        
        UNUserNotificationCenter.current().delegate = self  // Correctly set the delegate

        NotificationCenter.default.addObserver(forName: Notification.Name("login"), object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.login()
        }

        NotificationCenter.default.addObserver(forName: Notification.Name("logout"), object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.logOut()
        }
        
        // Persisted login check
        if User.current != nil {
            login()
        }
    }

    private func login() {
        let storyboard = UIStoryboard(name: Constants.storyboardIdentifier, bundle: nil)
        self.window?.rootViewController = storyboard.instantiateViewController(withIdentifier: Constants.feedNavigationControllerIdentifier)
    }

    private func logOut() {
        User.logout { [weak self] result in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    let storyboard = UIStoryboard(name: Constants.storyboardIdentifier, bundle: nil)
                    let viewController = storyboard.instantiateViewController(withIdentifier: Constants.loginNavigationControllerIdentifier)
                    self?.window?.rootViewController = viewController
                    self?.cancelPostReminder()
                }
            case .failure(let error):
                print("❌ Log out error: \(error)")
            }
        }
    }

    func cancelPostReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["postReminder"])
        print("✅ Post reminder notification canceled")
    }

    // Correct method signature for UNUserNotificationCenterDelegate
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])  // Show banner and play sound when in the foreground
    }

    func sceneDidDisconnect(_ scene: UIScene) { }
    func sceneDidBecomeActive(_ scene: UIScene) { }
    func sceneWillResignActive(_ scene: UIScene) { }
    func sceneWillEnterForeground(_ scene: UIScene) { }
    func sceneDidEnterBackground(_ scene: UIScene) { }
}
