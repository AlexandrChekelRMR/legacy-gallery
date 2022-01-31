//
//  GalleryMediaPresentable
//  LegacyGallery
//
//  Created by Alexander Chekel on 28.01.2022.
//

import UIKit

/// General implementation of `GalleryZoomTransitionDelegate` to ease up the basic usage.
public protocol GalleryMediaPresentable: UIViewController, GalleryZoomTransitionDelegate {
    /// Transition source image view provider.
    var sourceImageViewProvider: () -> UIImageView { get set }
    /// Content mode for image view that is being used during animated transitioning.
    var transitionImageViewContentMode: UIView.ContentMode { get }
}

public extension GalleryMediaPresentable {
    private var transitionImageViewFrame: CGRect {
        let imageView = sourceImageViewProvider()
        return imageView.superview?.convert(imageView.frame, to: nil) ?? .zero
    }

    // MARK: - GalleryMediaPresentable default implementations

    var transitionImageViewContentMode: UIView.ContentMode {
        .scaleAspectFit
    }

    // MARK: - GalleryZoomTransitionDelegate default implementations

    var zoomTransition: GalleryZoomTransition? {
        nil
    }

    var zoomTransitionInteractionController: UIViewControllerInteractiveTransitioning? {
        nil
    }

    var zoomTransitionAnimatingView: UIView? {
        let sourceImageView = sourceImageViewProvider()
        let transitionImageView = UIImageView(image: sourceImageView.image)
        transitionImageView.contentMode = transitionImageViewContentMode
        transitionImageView.clipsToBounds = true
        transitionImageView.layer.cornerRadius = sourceImageView.layer.cornerRadius
        transitionImageView.frame = transitionImageViewFrame
        return transitionImageView
    }

    func zoomTransitionHideViews(hide: Bool) {
        sourceImageViewProvider().alpha = hide ? 0 : 1
    }

    func zoomTransitionDestinationFrame(for view: UIView, frame: CGRect) -> CGRect {
        transitionImageViewFrame
    }
}
