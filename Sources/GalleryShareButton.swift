//
//  GalleryShareButton
//  LegacyGallery
//
//  Created by Alexander Chekel on 01.02.2022.
//

import UIKit

internal class GalleryShareButton: UIButton {
    var isLoading: Bool {
        get {
            activityIndicatorView.isAnimating
        }
        set {
            titleLabel?.isHidden = newValue

            if newValue {
                activityIndicatorView.startAnimating()
            } else {
                activityIndicatorView.stopAnimating()
            }
        }
    }

    override var contentEdgeInsets: UIEdgeInsets {
        didSet {
            switch effectiveUserInterfaceLayoutDirection {
                case .leftToRight:
                    activityIndicatorTrailingConstraint.constant = contentEdgeInsets.right
                case .rightToLeft:
                    activityIndicatorTrailingConstraint.constant = contentEdgeInsets.left
                @unknown default:
                    break
            }
        }
    }

    private let activityIndicatorView: UIActivityIndicatorView = UIActivityIndicatorView(style: .white)
    private var activityIndicatorTrailingConstraint: NSLayoutConstraint = NSLayoutConstraint()

    override init(frame: CGRect) {
        super.init(frame: frame)

        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activityIndicatorView)

        activityIndicatorTrailingConstraint = trailingAnchor.constraint(equalTo: activityIndicatorView.trailingAnchor)
        NSLayoutConstraint.activate([
            activityIndicatorTrailingConstraint,
            activityIndicatorView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
