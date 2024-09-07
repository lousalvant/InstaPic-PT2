//
//  PostCell.swift
//  project-2-lousalvant
//
//  Created by Lou-Michael Salvant on 9/6/24.
//

import UIKit

class PostCell: UITableViewCell {

    @IBOutlet private weak var usernameLabel: UILabel!
    @IBOutlet private weak var postImageView: UIImageView!
    @IBOutlet private weak var captionLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!

    private var imageDataTask: URLSessionDataTask?

    func configure(with post: Post) {
        // Username
        if let user = post.user {
            usernameLabel.text = user.username
        }

        // Image
        if let imageFile = post.imageFile,
           let imageUrl = imageFile.url {
            loadImage(from: imageUrl)
        }

        // Caption
        captionLabel.text = post.caption

        // Date
        if let date = post.createdAt {
            dateLabel.text = DateFormatter.postFormatter.string(from: date)
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

        // Reset image view image
        postImageView.image = nil
    }
}
