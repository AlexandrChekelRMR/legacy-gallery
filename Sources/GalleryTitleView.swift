//
//  GalleryTitleView
//  LegacyGallery
//
//  Created by Alexander Chekel on 03.02.2022.
//

import UIKit

public class GalleryTitleView: UIView {
    var closeAction: (() -> Void)?
    var shareAction: (() -> Void)?

    public let closeButton: UIButton = UIButton(type: .custom)
    public let shareButton: UIButton = GalleryShareButton(type: .custom)

    private let buttonsLayoutGuide: UILayoutGuide = UILayoutGuide()

    override public init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        closeButton.addTarget(self, action: #selector(closeButtonTap), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(closeButton)

        shareButton.addTarget(self, action: #selector(shareButtonTap), for: .touchUpInside)
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(shareButton)

        addLayoutGuide(buttonsLayoutGuide)

        NSLayoutConstraint.activate([
            buttonsLayoutGuide.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            buttonsLayoutGuide.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            buttonsLayoutGuide.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            buttonsLayoutGuide.bottomAnchor.constraint(equalTo: bottomAnchor),
            buttonsLayoutGuide.heightAnchor.constraint(equalToConstant: 44),

            closeButton.leadingAnchor.constraint(equalTo: buttonsLayoutGuide.leadingAnchor),
            closeButton.centerYAnchor.constraint(equalTo: buttonsLayoutGuide.centerYAnchor),
            closeButton.heightAnchor.constraint(equalTo: buttonsLayoutGuide.heightAnchor),

            shareButton.trailingAnchor.constraint(equalTo: buttonsLayoutGuide.trailingAnchor),
            shareButton.centerYAnchor.constraint(equalTo: buttonsLayoutGuide.centerYAnchor),
            shareButton.heightAnchor.constraint(equalTo: buttonsLayoutGuide.heightAnchor)
        ])
    }

    @objc private func closeButtonTap() {
        closeAction?()
    }

    @objc private func shareButtonTap() {
        shareAction?()
    }
}
