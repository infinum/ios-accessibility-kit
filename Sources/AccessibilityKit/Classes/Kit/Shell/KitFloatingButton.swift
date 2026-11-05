//
//  KitFloatingButton.swift
//  AccessibilityKit
//

import UIKit

///
/// The kit button: a 56 pt `selected` circle with the accessibility symbol,
/// floating above the app. Drag it and it springs to the nearest corner,
/// which it remembers across launches. Long-press it to hide it until the
/// next launch. VoiceOver users get the same through custom actions.
///
final class KitFloatingButton: UIButton {

    enum Corner: String, CaseIterable {
        case topLeading
        case topTrailing
        case bottomLeading
        case bottomTrailing

        var spokenName: String {
            switch self {
            case .topLeading: return "top leading"
            case .topTrailing: return "top trailing"
            case .bottomLeading: return "bottom leading"
            case .bottomTrailing: return "bottom trailing"
            }
        }
    }

    // MARK: - Internal properties

    static let size: CGFloat = 56

    /// Called on a long press, or the matching custom action.
    var onHide: (() -> Void)?

    /// Loaded once, written through, so layout passes never touch storage.
    private(set) var corner = KitFloatingButton.storedCorner() {
        didSet { UserDefaults.standard.set(corner.rawValue, forKey: Self.cornerKey) }
    }

    // MARK: - Private properties

    private let symbolView = UIImageView()
    /// Set while a drag is under way, so layout passes leave the button where the finger is.
    private var isDragging = false
    /// Where a long press began, so holding and then dragging moves the
    /// button instead of hiding it.
    private var longPressStart: (location: CGPoint, center: CGPoint)?
    private static let cornerKey = "com.infinum.AccessibilityKit.kitButtonCorner"
    /// Space from the side edges.
    private static let sideMargin: CGFloat = 20
    /// Space above the bottom safe area, enough to clear an app's bottom
    /// button or tab bar.
    private static let bottomMargin: CGFloat = 76
    /// Space below the top safe area, enough to clear a navigation bar.
    private static let topMargin: CGFloat = 64

    // MARK: - Lifecycle

    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: Self.size, height: Self.size))
        configure()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Overrides

    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.8 : 1 }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(ovalIn: bounds).cgPath
    }

    // MARK: - Internal methods

    /// Places the button in its corner of the superview.
    func moveToCorner(animated: Bool) {
        guard let superview, !isDragging else { return }
        let target = center(for: corner, in: superview)

        guard animated else {
            center = target
            return
        }

        if UIAccessibility.isReduceMotionEnabled {
            UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut, .beginFromCurrentState]) {
                self.center = target
            }
        } else {
            UIView.animate(
                withDuration: 0.35,
                delay: 0,
                usingSpringWithDamping: 0.75,
                initialSpringVelocity: 0,
                options: [.beginFromCurrentState, .allowUserInteraction]
            ) {
                self.center = target
            }
        }
    }
}

// MARK: - Private methods

private extension KitFloatingButton {

    func configure() {
        backgroundColor = .kit("kitSelected")
        tintColor = .kit("kitOnSelected")
        layer.cornerRadius = Self.size / 2
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: 4)

        let configuration = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
        symbolView.image = UIImage(systemName: "accessibility", withConfiguration: configuration)
        symbolView.isUserInteractionEnabled = false
        symbolView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(symbolView)
        NSLayoutConstraint.activate([
            symbolView.centerXAnchor.constraint(equalTo: centerXAnchor),
            symbolView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        accessibilityLabel = "Accessibility Kit"
        accessibilityHint = "Opens the kit's tools."
        accessibilityCustomActions = customActions()

        // The button keeps its size at every text size; a long press at an
        // accessibility text size shows it in the Large Content Viewer.
        showsLargeContentViewer = true
        largeContentTitle = "Accessibility Kit"
        largeContentImage = UIImage(systemName: "accessibility")
        addInteraction(UILargeContentViewerInteraction())

        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:))))
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.6
        addGestureRecognizer(longPress)
    }

    func customActions() -> [UIAccessibilityCustomAction] {
        let hide = UIAccessibilityCustomAction(name: "Hide until next launch") { [weak self] _ in
            self?.onHide?()
            return true
        }
        let moves = Corner.allCases.map { corner in
            UIAccessibilityCustomAction(name: "Move to \(corner.spokenName) corner") { [weak self] _ in
                self?.corner = corner
                self?.moveToCorner(animated: true)
                return true
            }
        }
        return [hide] + moves
    }

    @objc
    func handlePan(_ recognizer: UIPanGestureRecognizer) {
        guard let superview else { return }

        switch recognizer.state {
        case .began:
            isDragging = true
        case .changed:
            let translation = recognizer.translation(in: superview)
            center = CGPoint(x: center.x + translation.x, y: center.y + translation.y)
            recognizer.setTranslation(.zero, in: superview)
        case .ended, .cancelled, .failed:
            finishDrag(in: superview)
        default:
            break
        }
    }

    ///
    /// Held still and let go, the button hides. Held and then dragged — the
    /// way icons are picked up on the Home Screen — it moves instead, since
    /// a long press keeps the pan gesture from starting.
    ///
    @objc
    func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
        guard let superview else { return }
        let location = recognizer.location(in: superview)

        switch recognizer.state {
        case .began:
            longPressStart = (location, center)
        case .changed:
            guard let start = longPressStart else { return }
            let distance = hypot(location.x - start.location.x, location.y - start.location.y)
            if isDragging || distance > 10 {
                isDragging = true
                center = CGPoint(x: start.center.x + location.x - start.location.x, y: start.center.y + location.y - start.location.y)
            }
        case .ended:
            longPressStart = nil
            if isDragging {
                finishDrag(in: superview)
            } else if !traitCollection.preferredContentSizeCategory.isAccessibilityCategory {
                // At accessibility text sizes a long press belongs to the
                // Large Content Viewer; the "Hide until next launch" action
                // still hides.
                onHide?()
            }
        case .cancelled, .failed:
            longPressStart = nil
            if isDragging {
                finishDrag(in: superview)
            }
        default:
            break
        }
    }

    /// Ends a drag: the button springs to the corner nearest where it was let go.
    func finishDrag(in superview: UIView) {
        isDragging = false
        corner = nearestCorner(to: center, in: superview)
        moveToCorner(animated: true)
    }

    static func storedCorner() -> Corner {
        return UserDefaults.standard.string(forKey: cornerKey).flatMap(Corner.init(rawValue:)) ?? .bottomTrailing
    }

    func center(for corner: Corner, in container: UIView) -> CGPoint {
        let bounds = container.bounds
        let insets = container.safeAreaInsets
        let half = Self.size / 2
        let isRightToLeft = effectiveUserInterfaceLayoutDirection == .rightToLeft

        let left = insets.left + Self.sideMargin + half
        let right = bounds.width - insets.right - Self.sideMargin - half
        let top = insets.top + Self.topMargin + half
        let bottom = bounds.height - insets.bottom - Self.bottomMargin - half

        switch corner {
        case .topLeading: return CGPoint(x: isRightToLeft ? right : left, y: top)
        case .topTrailing: return CGPoint(x: isRightToLeft ? left : right, y: top)
        case .bottomLeading: return CGPoint(x: isRightToLeft ? right : left, y: bottom)
        case .bottomTrailing: return CGPoint(x: isRightToLeft ? left : right, y: bottom)
        }
    }

    func nearestCorner(to point: CGPoint, in container: UIView) -> Corner {
        return Corner.allCases.min { lhs, rhs in
            distance(point, center(for: lhs, in: container)) < distance(point, center(for: rhs, in: container))
        } ?? .bottomTrailing
    }

    func distance(_ lhs: CGPoint, _ rhs: CGPoint) -> CGFloat {
        return hypot(lhs.x - rhs.x, lhs.y - rhs.y)
    }
}
