//
//  AccessibilityMonitorViewController.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 11.02.2022..
//

import UIKit

final class AccessibilityMonitorViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet private weak var tableView: UITableView!

    // MARK: - Private properties

    private var items = [AccessibilityState]() {
        didSet {
            tableView.reloadData()
        }
    }

    private lazy var numberFormatter = {
        return NumberFormatter()
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()

        AccessibilityKit.shared.observeAccessibilityTracking { [weak self] snapshot in
            self?.items = snapshot.states
        }
    }

    // MARK: - Public methods

    static func loadViewController() -> UIViewController? {
        let storyboard = UIStoryboard(
            name: String(describing: Self.self),
            bundle: Bundle.frameworkBundle(for: AccessibilityMonitorViewController.self)
        )
        return storyboard.instantiateInitialViewController()
    }
}

// MARK: - Extensions

extension AccessibilityMonitorViewController: UITableViewDelegate, UITableViewDataSource {

    // MARK: - UITableViewDelegate & UITableViewDelegate

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            ofType: AccessibilityMonitorTableViewCell.self,
            for: indexPath
        )
        cell.configure(with: items[indexPath.row], formatter: numberFormatter)
        return cell
    }
}

// MARK: - Private methods

extension AccessibilityMonitorViewController {

    func setupView() {
        title = "Accessibility Kit"

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeAction)
        )
    }

    @objc
    func closeAction() {
        dismiss(animated: true, completion: nil)
    }
}
