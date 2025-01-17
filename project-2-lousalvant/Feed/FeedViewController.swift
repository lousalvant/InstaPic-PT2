//
//  FeedViewController.swift
//  project-2-lousalvant
//
//  Created by Lou-Michael Salvant on 9/6/24.
//

import UIKit
import ParseSwift

class FeedViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    private var posts = [Post]() {
        didSet {
            tableView.reloadData()
        }
    }
    
    // Stretch Feature: Create refresh control instance
    private let refreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 150
        
        // Set up notification observer for when the user successfully posts
        NotificationCenter.default.addObserver(self, selector: #selector(refreshFeed), name: Notification.Name("postSuccess"), object: nil)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = false
        
        // Stretch Feature: Refresh control set up
        refreshControl.addTarget(self, action: #selector(refreshFeed), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        queryPosts()
        
        // Add gesture recognizer to dismiss keyboard when tapping outside the text field
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
        
    // Function to dismiss the keyboard
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        queryPosts()
    }
    
    // Stretch Feature: Refresh feed method
    @objc private func refreshFeed() {
            queryPosts()
    }

    private var hasUserPosted: Bool {
        return User.current?.lastPostedDate != nil
    }

    private func queryPosts() {
        let yesterdayDate = Calendar.current.date(byAdding: .hour, value: -24, to: Date())!

        let query = Post.query()
            .include("comments")
            .include("user")
            .order([.descending("createdAt")])
            .where("createdAt" >= yesterdayDate)
            .limit(10)

        // Fetch posts
        query.find { [weak self] result in
            DispatchQueue.main.async {
                // End refresh when data is loaded
                self?.refreshControl.endRefreshing()
            }

            switch result {
            case .success(let posts):
                self?.posts = posts

            case .failure(let error):
                self?.showAlert(description: error.localizedDescription)
            }
        }
    }

    @IBAction func onLogOutTapped(_ sender: Any) {
        showConfirmLogoutAlert()
    }

    private func showConfirmLogoutAlert() {
        let alertController = UIAlertController(title: "Log out of your account?", message: nil, preferredStyle: .alert)
        let logOutAction = UIAlertAction(title: "Log out", style: .destructive) { _ in
            NotificationCenter.default.post(name: Notification.Name("logout"), object: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(logOutAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }

    private func showAlert(description: String? = nil) {
        let alertController = UIAlertController(title: "Oops...", message: "\(description ?? "Please try again...")", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(action)
        present(alertController, animated: true)
    }
}

extension FeedViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as? PostCell else {
            return UITableViewCell()
        }

        // Pass the `hasUserPosted` flag to the cell
        cell.configure(with: posts[indexPath.row], hasUserPosted: hasUserPosted)
        return cell
    }
}

extension FeedViewController: UITableViewDelegate {
    
}

extension FeedViewController: PostCellDelegate {
    
    func didTapPostComment(for post: Post, with comment: String) {
        var postToUpdate = post
        
        let newComment = Comment(username: User.current?.username, content: comment)
        
        // Append new comment to post's comments array
        if postToUpdate.comments == nil {
            postToUpdate.comments = []
        }
        postToUpdate.comments?.append(newComment)
        
        // Save the updated post with the new comment
        postToUpdate.save { [weak self] result in
            switch result {
            case .success:
                print("✅ Comment posted successfully")
                self?.refreshFeed() // Reload feed to show new comment
            case .failure(let error):
                print("❌ Failed to post comment: \(error.localizedDescription)")
            }
        }
    }
}
