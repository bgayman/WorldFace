//
//  ViewController.swift
//  WorldFace
//
//  Created by brad.gayman on 7/15/19.
//  Copyright © 2019 brad.gayman. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    lazy var faceGeometry: ARSCNFaceGeometry = {
        let device = sceneView.device!
        let maskGeometry = ARSCNFaceGeometry(device: device)!
        maskGeometry.firstMaterial?.lightingModel = .physicallyBased
        maskGeometry.firstMaterial?.diffuse.contents = UIColor.lightGray
        maskGeometry.firstMaterial?.metalness.contents = UIColor.white
        maskGeometry.firstMaterial?.roughness.contents = UIColor.black
        return maskGeometry
    }()

    lazy var tapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        return gesture
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Set the scene to the view
        sceneView.scene = SCNScene()
        sceneView.addGestureRecognizer(tapGesture)
        sceneView.automaticallyUpdatesLighting = true
        sceneView.autoenablesDefaultLighting = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Check if device supports face tracking
        if ARFaceTrackingConfiguration.isSupported {
            configuration.userFaceTrackingEnabled = true
        } else {
            // Fall back to world tracking only experience
        }
        configuration.isLightEstimationEnabled = true
        configuration.planeDetection = [.horizontal]

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    @objc func didTap(_ recognizer: UITapGestureRecognizer) {
        // Get tap location
        let tapLocation = recognizer.location(in: sceneView)
        
        // Perform hit test with detected planes
        let hitTestResults = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)

        // Guard that a result exits
        guard let hitTestResult = hitTestResults.first else { return }
        
        // Create anchor from result
        let newAnchor = ARAnchor(transform: hitTestResult.worldTransform)
        
        // Add to session and wait for callback
        sceneView.session.add(anchor: newAnchor)
    }

    // MARK: - ARSCNViewDelegate

    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        if let planeAnchor = anchor as? ARPlaneAnchor {
            let node = SCNNode()
            let planeGeometry = ARSCNPlaneGeometry(device: sceneView.device!)
            planeGeometry?.update(from: planeAnchor.geometry)
            planeGeometry?.firstMaterial?.diffuse.contents = UIColor.blue.withAlphaComponent(0.5)
            node.geometry = planeGeometry
            return node
        } else {
            let node = SCNNode()
            node.geometry = faceGeometry
            node.position = SCNVector3(0.0, 0.15, 0.0)
            let parentNode = SCNNode()
            parentNode.addChildNode(node)
            return parentNode
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // Check if face anchor
        if let faceAnchor = anchor as? ARFaceAnchor {
            
            // Update node geometry using anchor geometry
            faceGeometry.update(from: faceAnchor.geometry)
            
        }
        // Check if plane anchor
        else if let anchor = anchor as? ARPlaneAnchor,
            let plane = node.geometry as? ARSCNPlaneGeometry {
            
            // Update node geometry using anchor geometry
            plane.update(from: anchor.geometry)
        }
    }

    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
