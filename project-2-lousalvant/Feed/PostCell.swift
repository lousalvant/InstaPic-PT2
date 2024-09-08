import UIKit
import CoreLocation

class PostCell: UITableViewCell {

    @IBOutlet private weak var usernameLabel: UILabel!
    @IBOutlet private weak var postImageView: UIImageView!
    @IBOutlet private weak var captionLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel! // Stretch Feature: Location outlet

    private var imageDataTask: URLSessionDataTask?
    private let geocoder = CLGeocoder()

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

        // Stretch Feature: Location
        if let location = post.location {
            let latitude = location.latitude
            let longitude = location.longitude

            // Use reverse geocoding to get the location name
            geocoder.reverseGeocodeLocation(CLLocation(latitude: latitude, longitude: longitude)) { [weak self] placemarks, error in
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
