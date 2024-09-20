import UIKit
import CoreLocation

protocol PostCellDelegate: AnyObject {
    func didTapPostComment(for post: Post, with comment: String)
}

class PostCell: UITableViewCell {

    @IBOutlet private weak var usernameLabel: UILabel!
    @IBOutlet private weak var postImageView: UIImageView!
    @IBOutlet private weak var captionLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel! // Stretch Feature: Location outlet

    @IBOutlet weak var blurView: UIVisualEffectView!
    
    @IBOutlet weak var commentsStackView: UIStackView!
    @IBOutlet weak var commentTextField: UITextField!
    @IBOutlet weak var postCommentButton: UIButton!
    
    weak var delegate: PostCellDelegate?
    var post: Post?
    private var comments = [Comment]()
        
    private var imageDataTask: URLSessionDataTask?
    private let geocoder = CLGeocoder()

    func configure(with post: Post, hasUserPosted: Bool) {
        self.post = post
        comments = post.comments ?? []

        // Clear previous comments from the stack view
        for view in commentsStackView.arrangedSubviews {
            commentsStackView.removeArrangedSubview(view)
            view.removeFromSuperview() // Ensure the view is removed from the hierarchy
        }

        // Add comments to the stack view
        if !comments.isEmpty {
            for comment in comments {
                let commentLabel = UILabel()
                commentLabel.text = "\(comment.username ?? "Unknown"): \(comment.content ?? "")"
                commentLabel.numberOfLines = 0
                commentLabel.font = UIFont.systemFont(ofSize: 14) // Optional: Adjust the font size
                commentsStackView.addArrangedSubview(commentLabel)
            }
        } else {
            // Show a message if no comments exist
            let noCommentsLabel = UILabel()
            noCommentsLabel.text = "Be the first to comment!"
            noCommentsLabel.textAlignment = .center
            noCommentsLabel.font = UIFont.italicSystemFont(ofSize: 14) // Optional: Style for "no comments"
            commentsStackView.addArrangedSubview(noCommentsLabel)
        }

        // Ensure UI updates happen on the main thread
        DispatchQueue.main.async {
            // Username
            if let user = post.user {
                self.usernameLabel.text = user.username
            }

            // Image
            if let imageFile = post.imageFile, let imageUrl = imageFile.url {
                self.loadImage(from: imageUrl)
            }

            // Caption
            self.captionLabel.text = post.caption

            // Date
            if let date = post.createdAt {
                self.dateLabel.text = DateFormatter.postFormatter.string(from: date)
            }

            // Show or hide the blur view depending on whether the current user has posted
            self.blurView.isHidden = hasUserPosted

            // Stretch Feature: Location
            if let location = post.location {
                let latitude = location.latitude
                let longitude = location.longitude

                // Use reverse geocoding to get the location name
                self.geocoder.reverseGeocodeLocation(CLLocation(latitude: latitude, longitude: longitude)) { [weak self] placemarks, error in
                    guard let self = self else { return }

                    if let placemark = placemarks?.first {
                        let city = placemark.locality ?? "Unknown city"
                        let state = placemark.administrativeArea ?? "Unknown state"
                        
                        // Combine city and state into a single string
                        let locationText = "\(city), \(state)"
                        
                        DispatchQueue.main.async {
                            self.locationLabel.text = locationText
                        }
                    } else if let error = error {
                        print("❌ Error reverse geocoding: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    @IBAction func postCommentTapped(_ sender: UIButton) {
        self.endEditing(true)

        guard let commentText = commentTextField.text, !commentText.isEmpty else {
            print("No comment entered")
            return
        }

        guard var postToUpdate = post else {
            print("Post is nil")
            return
        }

        let newComment = Comment(username: User.current?.username, content: commentText)

        // Add the new comment to the post's comment array
        if postToUpdate.comments == nil {
            postToUpdate.comments = []
        }
        postToUpdate.comments?.append(newComment)

        // Save the post with the updated comments
        postToUpdate.save { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("✅ Comment added successfully")
                    
                    // Clear the comment input text field
                    self?.commentTextField.text = ""
                    
                    // Reload the comments in the UI
                    self?.configure(with: postToUpdate, hasUserPosted: true)
                    
                case .failure(let error):
                    print("❌ Failed to add comment: \(error.localizedDescription)")
                }
            }
        }
    }



    private func loadImage(from url: URL) {
        // Cancel any previous image loading task
        imageDataTask?.cancel()

        // Fetch the image data
        imageDataTask = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self, let data = data, let image = UIImage(data: data) else {
                if let error = error {
                    print("❌ Error fetching image: \(error.localizedDescription)")
                }
                return
            }

            // UI updates must be on the main thread
            DispatchQueue.main.async {
                self.postImageView.image = image
            }
        }

        // Start the image data task
        imageDataTask?.resume()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        // Cancel any pending image download
        imageDataTask?.cancel()

        // Reset image view image and location label
        postImageView.image = nil
        locationLabel.text = nil
    }
}

extension PostCell: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath)
        let comment = comments[indexPath.row]
        cell.textLabel?.text = "\(comment.username ?? "Unknown"): \(comment.content ?? "")"
        return cell
    }
}
