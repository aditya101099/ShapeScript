//
//  WhatsNewViewController.swift
//  Viewer (iOS)
//
//  Created by Nick Lockwood on 23/04/2023.
//  Copyright © 2023 Nick Lockwood. All rights reserved.
//

import UIKit

func loadRTF(_ file: String) throws -> NSAttributedString {
    let file = Bundle.main.url(forResource: file, withExtension: "rtf")!
    let data = try! Data(contentsOf: file)
    return try NSAttributedString(data: data, documentAttributes: nil)
}

class WhatsNewViewController: UIViewController {
    @IBOutlet private var textView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "What's New in ShapeScript?"
        textView.attributedText = try! loadRTF("WhatsNew")

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            systemItem: .close,
            primaryAction: UIAction { [weak self] _ in
                self?.dismiss(animated: true)
            }
        )
    }
}
