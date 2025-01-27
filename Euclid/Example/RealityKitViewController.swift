//
//  RealityKitViewController.swift
//  Example
//
//  Created by Nick Lockwood on 22/10/2022.
//  Copyright © 2022 Nick Lockwood. All rights reserved.
//

import Combine
import Euclid
import RealityKit
import UIKit

class RealityKitViewController: UIViewController {
    var updateSubscription: Cancellable!

    override func viewDidLoad() {
        super.viewDidLoad()

        let arView = ARView(
            frame: view.frame,
            cameraMode: .nonAR,
            automaticallyConfigureSession: false
        )
        arView.environment.background = .color(.white)
        arView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(arView)

        if #available(macOS 12.0, iOS 15.0, *) {
            // create ModelEntity
            if let entity = try? ModelEntity(euclidMesh) {
                let anchor = AnchorEntity(world: .zero)
                anchor.addChild(entity)
                arView.scene.anchors.append(anchor)
            }
        } else {
            let alert = UIAlertController(
                title: "Unsupported",
                message: "Euclid RealityKit support requires a minimum of iOS 15.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            present(alert, animated: true)
        }

        let camera = PerspectiveCamera()
        let cameraAnchor = AnchorEntity(world: .zero)
        cameraAnchor.addChild(camera)
        arView.scene.addAnchor(cameraAnchor)

        var cameraOffset = Vector(0, 0, 2)
        let rotationSpeed = Angle.pi / 4

        updateSubscription = arView.scene.subscribe(to: SceneEvents.Update.self) { event in
            cameraOffset.rotate(by: .yaw(rotationSpeed * event.deltaTime))

            let cameraTranslation = SIMD3<Float>(cameraOffset)
            camera.transform = Transform(translation: cameraTranslation)
            camera.look(at: .zero, from: cameraTranslation, relativeTo: nil)
        }
    }
}
