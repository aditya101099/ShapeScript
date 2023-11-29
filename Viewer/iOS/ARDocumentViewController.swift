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

class ARDocumentViewController: UIViewController {
    
    var arSceneView: ARSCNView = .init()
    var model: SCNNode!
    
    enum AppState {
      case DetectSurface
      case PointAtSurface
      case TapToStart
      case Started
    }
    
    // App state management
    var trackingStatus: String = ""
    var statusMessage: String = ""
    var appState: AppState = .DetectSurface
    
    var statusLabel: UILabel!
    
    init(model: SCNNode) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        // Configure the ARSCNView
        arSceneView.frame = view.bounds
        view.addSubview(arSceneView)
        
        // Configure label
        statusLabel = UILabel()
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)
        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 5),
            statusLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 5),
            statusLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -5),
        ])
        
        // Create a new ARWorldTrackingConfiguration
        let configuration = ARWorldTrackingConfiguration()
        arSceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

        // Add a tap gesture recognizer to handle surface selection
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        arSceneView.addGestureRecognizer(tapGesture)
    }
    
    // Handle tap on the AR scene to place all models
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        let tapLocation = gesture.location(in: arSceneView)
        if #available(iOS 13, *) {
            let rayCastQueryResult = arSceneView.raycastQuery(from: tapLocation, allowing: .existingPlaneGeometry, alignment: .horizontal)
            if let position = rayCastQueryResult?.origin {
                // Set the desired size for the models (adjust as needed)
                let targetSize: CGFloat = 0.01
                let newNode = model.clone()
                // Calculate the bounding box of the model
                let (min, max) = newNode.boundingBox
                let size = SCNVector3Make(max.x - min.x, max.y - min.y, max.z - min.z)

                // Calculate the scale factor based on the target size
                let scaleFactor = targetSize / CGFloat(size.x)

                newNode.position = SCNVector3(position)
                newNode.scale = SCNVector3(scaleFactor, scaleFactor, scaleFactor)
                
//                if arSceneView.scene.rootNode.childNodes == [] {
                    arSceneView.scene.rootNode.addChildNode(newNode)
//                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Pause the AR session when the view controller disappears
        arSceneView.session.pause()
    }
}

extension ARDocumentViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
          self.updateStatus()
        }
    }
}

extension ARDocumentViewController {
    // For state management
    func startARView() {
      DispatchQueue.main.async {
        self.appState = .DetectSurface
      }
    }
    
    func resetApp() {
        DispatchQueue.main.async {
            //self.resetARSession()
            self.appState = .DetectSurface
        }
    }
    
    func updateStatus() {
      switch appState {
      case .DetectSurface:
        statusMessage = "Scan available flat surfaces..."
      case .PointAtSurface:
        statusMessage = "Point at designated surface first!"
      case .TapToStart:
        statusMessage = "Tap to start."
      case .Started:
        statusMessage = "Tap objects for more info."
      }

      self.statusLabel.text = trackingStatus != "" ?
          "\(trackingStatus)" : "\(statusMessage)"
    }
}
