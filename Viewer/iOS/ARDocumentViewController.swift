//
//  ARDocumentViewController.swift
//  ShapeScript
//
//  Created by Aditya Rudrapatna on 08/11/2023.
//  Copyright © 2023 Nick Lockwood. All rights reserved.
//

import ARKit
import SceneKit
import UIKit

class ARDocumentViewController: UIViewController, ARSCNViewDelegate {
    
    var arSceneView: ARSCNView = .init()
    var model: SCNNode!
    
    init(model: SCNNode) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        arSceneView.frame = view.bounds
        
        arSceneView.delegate = self
        view.addSubview(arSceneView)
        
        // Create a new ARWorldTrackingConfiguration
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravity
        configuration.providesAudioData = false
        configuration.planeDetection = .horizontal
        configuration.isLightEstimationEnabled = true
        configuration.environmentTexturing = .automatic
        arSceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

        // Add a tap gesture recognizer to handle surface selection
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        arSceneView.addGestureRecognizer(tapGesture)
    }
    
    // Handle tap on the AR scene to place all models
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else { return }
        let tapLocation = gesture.location(in: arSceneView)
        
        // Remove existing nodes
        arSceneView.scene.rootNode.childNodes.forEach { $0.removeFromParentNode() }
        
        // Get hit location
        if let query = arSceneView.raycastQuery(from: tapLocation, allowing: .estimatedPlane, alignment: .horizontal) {
            let results = arSceneView.session.raycast(query)
            
            if results.count == 1 {
                if let match = results.first {
                    let t = match.worldTransform
                    let position = SCNVector3(x: t.columns.3.x, y: t.columns.3.y, z: t.columns.3.z)
                    let targetSize: CGFloat = 0.5
                    let newNode = model.clone()
                    newNode.position = position
                    // Calculate the bounding box of the model
                    let (min, max) = newNode.boundingBox
                    let size = SCNVector3Make(max.x - min.x, max.y - min.y, max.z - min.z)
                    // Calculate the scale factor based on the target size
                    let scaleFactor = targetSize / CGFloat(size.x)
                    newNode.scale = SCNVector3(scaleFactor, scaleFactor, scaleFactor)
                    arSceneView.scene.rootNode.addChildNode(newNode)
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Pause the AR session when the view controller disappears
        arSceneView.session.pause()
    }
}
