//
//  AccessibilityMonitorViewController.swift
//  AccessibilityKit
//
//  Created by Nikola Majcen on 11.02.2022..
//

import UIKit

public final class AccessibilityMonitorViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet private weak var tableView: UITableView!

    // MARK: - Private properties

    private var items = [AccessibilityState]() {
        didSet {
            tableView.reloadData()
        }
    }

    public static func loadViewController() -> UIViewController? {
        let storyboard = UIStoryboard(name: "AccessibilityMonitor", bundle: Bundle(for: AccessibilityMonitorViewController.self))
        let viewController = storyboard.instantiateInitialViewController()
        return viewController
    }

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "Accessibility Monitor"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeAction)
        )

        AccessibilityKit.shared.observeStateChanges { [unowned self] in items = $0.states }
    }

    @objc func closeAction() {
        dismiss(animated: true, completion: nil)
    }
}

extension AccessibilityMonitorViewController: UITableViewDelegate, UITableViewDataSource {

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AccessibilityMonitorTableViewCell", for: indexPath) as! AccessibilityMonitorTableViewCell
        cell.configure(title: items[indexPath.row].name, enabled: items[indexPath.row].enabled)
        return cell
    }
}
