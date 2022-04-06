//
// GalleryItemViewController
// LegacyGallery
//
// Copyright (c) 2018 Eugene Egorov.
// License: MIT, https://github.com/eugeneego/legacy/blob/master/LICENSE
//

import UIKit

public struct GalleryControls: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let close: GalleryControls = GalleryControls(rawValue: 1)
    public static let share: GalleryControls = GalleryControls(rawValue: 2)
}

@available(iOSApplicationExtension, unavailable)
open class GalleryItemViewController: UIViewController, GalleryZoomTransitionDelegate {
    open var index: Int = 0

    open var closeAction: (() -> Void)?
    open var shareAction: ((GalleryMedia, @escaping () -> Void) -> Void)?
    open var shareCompletionHandler: ((Result<GalleryMedia, Error>, UIActivity.ActivityType?) -> Void)?
    open var presenterInterfaceOrientations: (() -> UIInterfaceOrientationMask?)?
    open var statusBarStyle: UIStatusBarStyle = .lightContent
    open var isTransitionEnabled: Bool = true

    open var showRetryButton: Bool = false
    open var autoplay: Bool = true
    open var sharedControls: Bool = true
    open var availableControls: GalleryControls = [ .close, .share ]
    open internal(set) var controls: GalleryControls = [ .close, .share ]
    open var controlsChanged: (() -> Void)?
    open var initialControlsVisibility: Bool = false
    open internal(set) var controlsVisibility: Bool = false
    open var controlsVisibilityChanged: ((Bool) -> Void)?

    internal var mediaSize: CGSize = .zero

    // MARK: - View Controller

    open override func viewDidLoad() {
        super.viewDidLoad()

        modalPresentationStyle = .fullScreen
        extendedLayoutIncludesOpaqueBars = true
        view.backgroundColor = .black
    }

    open override var prefersStatusBarHidden: Bool {
        statusBarHidden
    }

    open override var preferredStatusBarStyle: UIStatusBarStyle {
        statusBarStyle
    }

    open override var shouldAutorotate: Bool {
        true
    }

    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .all
    }

    // MARK: - Controls

    public let titleView: GalleryTitleView = GalleryTitleView()
    public let loadingIndicatorView: UIActivityIndicatorView = UIActivityIndicatorView(style: .whiteLarge)
    public let retryButton: UIButton = UIButton(type: .custom)
    public let tapGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer()

    internal var statusBarHidden: Bool = false

    var galleryShareButton: GalleryShareButton? {
        let galleryViewController = parent as? GalleryViewController
        let sharedControls = galleryViewController?.sharedControls ?? false

        return sharedControls
            ? galleryViewController?.titleView.shareButton as? GalleryShareButton
            : titleView.shareButton as? GalleryShareButton
    }

    open var isShareAvailable: Bool {
        false
    }

    open func setupCommonControls() {
        animatingImageView.translatesAutoresizingMaskIntoConstraints = true
        animatingImageView.contentMode = .scaleAspectFill
        animatingImageView.clipsToBounds = true
        animatingImageView.backgroundColor = .clear

        // Title View

        titleView.translatesAutoresizingMaskIntoConstraints = false
        titleView.backgroundColor = UIColor(white: 0, alpha: 0.7)
        titleView.isUserInteractionEnabled = true
        view.addSubview(titleView)

        titleView.closeButton.setTitle("Close", for: .normal)
        titleView.closeButton.setTitleColor(.white, for: .normal)
        titleView.closeButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)

        titleView.shareButton.setTitle("Share", for: .normal)
        titleView.shareButton.setTitleColor(.white, for: .normal)
        titleView.shareButton.setTitleColor(.clear, for: .disabled)
        titleView.shareButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)

        titleView.closeAction = { [unowned self] in
            closeTap()
        }
        titleView.shareAction = { [unowned self] in
            shareTap()
        }

        tapGestureRecognizer.addTarget(self, action: #selector(toggleTap))
        view.addGestureRecognizer(tapGestureRecognizer)

        // Loading Indicator

        loadingIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicatorView.hidesWhenStopped = true
        loadingIndicatorView.color = .white
        view.addSubview(loadingIndicatorView)

        // Retry button

        retryButton.translatesAutoresizingMaskIntoConstraints = false
        retryButton.addTarget(self, action: #selector(retryTap), for: .touchUpInside)
        retryButton.isHidden = true
        view.addSubview(retryButton)

        // Constraints

        NSLayoutConstraint.activate([
            titleView.topAnchor.constraint(equalTo: view.topAnchor),
            titleView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            titleView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicatorView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            retryButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            retryButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        // Initial state

        titleView.isHidden = sharedControls || !controlsVisibility
        showControls(initialControlsVisibility, animated: false)

        updateControls()
    }

    open func showControls(_ show: Bool, animated: Bool) {
        controlsVisibility = show
        statusBarHidden = !show

        guard !sharedControls else {
            controlsVisibilityChanged?(controlsVisibility)
            return
        }

        if show {
            titleView.isHidden = false
        }

        UIView.animate(withDuration: animated ? 0.15 : 0, delay: 0, options: [],
            animations: {
                self.setNeedsStatusBarAppearanceUpdate()
                self.titleView.alpha = show ? 1 : 0
                self.controlsVisibilityChanged?(self.controlsVisibility)
            },
            completion: { finished in
                if finished {
                    self.titleView.isHidden = !show
                }
            }
        )
    }

    @objc open func toggleTap() {
        showControls(!controlsVisibility, animated: true)
    }

    @objc open func retryTap() {
        // To be overriden
    }

    open func closeTap() {
        isTransitioning = true

        close()
    }

    private func close() {
        if let closeAction = closeAction {
            closeAction()
        } else {
            dismiss(animated: true, completion: nil)
        }
    }

    open func shareTap() {
        // To be overriden
    }

    internal func updateControls() {
        let closeAvailable = availableControls.contains(.close)
        if closeAvailable {
            controls.insert(.close)
        } else {
            controls.remove(.close)
        }
        titleView.closeButton.isHidden = !closeAvailable

        // Share only local videos
        let shareAvailable = isShareAvailable && availableControls.contains(.share)
        if shareAvailable {
            controls.insert(.share)
        } else {
            controls.remove(.share)
        }
        titleView.shareButton.isEnabled = shareAvailable

        controlsChanged?()
    }

    // MARK: - Transition

    internal var isTransitioning: Bool = false
    internal var transition: GalleryZoomTransition = GalleryZoomTransition(interactive: false)
    internal var animatingImageView: UIImageView = UIImageView()

    open func setupTransition() {
        transition.startTransition = { [weak self] in
            self?.close()
        }
        transition.shouldStartInteractiveTransition = { [weak self] in
            guard let self = self else { return true }

            let orientation: UInt = 1 << UIApplication.shared.statusBarOrientation.rawValue
            let supportedOrientations = self.presenterInterfaceOrientations?()
                ?? self.presentingViewController?.supportedInterfaceOrientations
                ?? .portrait
            let isFullInteractive = supportedOrientations.rawValue & orientation > 0

            self.transition.interactive = true
            self.transition.sourceTransition = self

            self.zoomTransitionOnStart()

            self.isTransitioning = true

            return isFullInteractive
        }
        transition.sourceRootView = { [weak self] in
            self?.view
        }
        transition.completion = { [weak self] _ in
            guard let self = self else { return }

            self.transition.interactive = false
            self.isTransitioning = false
        }
        view.addGestureRecognizer(transition.panGestureRecognizer)
        transition.panGestureRecognizer.isEnabled = isTransitionEnabled
    }

    open func zoomTransitionOnStart() {
        // to be overridden
    }

    open var zoomTransition: GalleryZoomTransition? {
        transition
    }

    open var zoomTransitionInteractionController: UIViewControllerInteractiveTransitioning? {
        transition.interactive ? transition : nil
    }

    open var zoomTransitionAnimatingView: UIView? {
        zoomTransitionPrepareAnimatingView(animatingImageView)
        return animatingImageView
    }

    open func zoomTransitionPrepareAnimatingView(_ animatingImageView: UIImageView) {
        // to be overridden
    }

    open func zoomTransitionHideViews(hide: Bool) {
        titleView.isHidden = hide || !controlsVisibility || sharedControls
    }

    open func zoomTransitionDestinationFrame(for view: UIView, frame: CGRect) -> CGRect {
        var result = frame
        let viewSize = frame.size

        if mediaSize.width > 0.1 && mediaSize.height > 0.1 {
            let imageRatio = mediaSize.height / mediaSize.width
            let viewRatio = viewSize.height / viewSize.width

            result.size = imageRatio <= viewRatio
                ? CGSize(
                width: viewSize.width,
                height: (viewSize.width * (mediaSize.height / mediaSize.width)).rounded(.toNearestOrAwayFromZero)
            )
                : CGSize(
                width: (viewSize.height * (mediaSize.width / mediaSize.height)).rounded(.toNearestOrAwayFromZero),
                height: viewSize.height
            )
            result.origin = CGPoint(
                x: (viewSize.width / 2 - result.size.width / 2).rounded(.toNearestOrAwayFromZero),
                y: (viewSize.height / 2 - result.size.height / 2).rounded(.toNearestOrAwayFromZero)
            )
        }

        return result
    }
}
