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

    static func loadViewController() -> UIViewController? {
        let storyboard = UIStoryboard(
            name: "AccessibilityMonitorViewController",
            bundle: Bundle.frameworkBundle(for: AccessibilityMonitorViewController.self)
        )
        let viewController = storyboard.instantiateInitialViewController()
        return viewController
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Accessibility Monitor"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeAction)
        )

        AccessibilityKit.shared.observeAccessibilityTracking { [unowned self] in items = $0.states }
    }

    @objc func closeAction() {
        dismiss(animated: true, completion: nil)
    }
}

extension AccessibilityMonitorViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "AccessibilityMonitorTableViewCell",
            for: indexPath
        ) as! AccessibilityMonitorTableViewCell

        let item = items[indexPath.row]
        let enabled: Bool
        switch item.value {
        case .flag(let flag):
            enabled = flag
        case .number:
            enabled = false
        }

        cell.configure(title: item.name, enabled: enabled)
        return cell
    }
}
