//
//  ViewController.swift
//  HelloAR
//
//  Created by Minxin Guo on 6/30/17.
//  Copyright © 2017 Minxin Guo. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {
    
    // MARK: - Properties
    @IBOutlet var sceneView: ARSCNView!
    fileprivate var planes = [OverlayPlane]()
    
    // MARK: - View related functions
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        scene.rootNode.addChildNode(createBoxContent())
        scene.rootNode.addChildNode(createTextContent())
        scene.rootNode.addChildNode(createSphereContent())
        scene.rootNode.addChildNode(createMissile())
        
        // Set the scene to the view
        sceneView.scene = scene
        
        // Add tap gesture
        addGestures()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingSessionConfiguration()
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // MARK: - Gestures
    private func addGestures() {
        // Single Tap Gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(singleTapHandler))
        
        // Double tap gesture
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(doubleTapHandler))
        doubleTapGesture.numberOfTapsRequired = 2
        
        // NOTE: This is REQUIRED to use both taps at the same time
        tapGesture.require(toFail: doubleTapGesture)
        
        // Long press
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressHandler))
        longPressGesture.minimumPressDuration = 1.0
        
        // Swipe gesture
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(swipeHandler))
        swipeGesture.direction = .up
        
        // Add gestures to view
        sceneView.addGestureRecognizer(tapGesture)
        sceneView.addGestureRecognizer(doubleTapGesture)
        sceneView.addGestureRecognizer(longPressGesture)
        sceneView.addGestureRecognizer(swipeGesture)
    }
    
    @objc func swipeHandler(recognizer: UISwipeGestureRecognizer) {
        guard let missileNode = sceneView.scene.rootNode.childNode(withName: "missile", recursively: true) else {
            fatalError("missile is not found")
        }
        missileNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        missileNode.physicsBody?.isAffectedByGravity = false // Just for demo
        missileNode.physicsBody?.damping = 0.0 // A property that will decrease the speed
        missileNode.physicsBody?.applyForce(SCNVector3(0, 100, 0), asImpulse: false)
        
        // Add fire for launching
        guard let smokeNode = missileNode.childNode(withName: "smokeNode", recursively: true) else {
            fatalError("No smoke node is found")
        }
        smokeNode.removeAllParticleSystems()
        let fire = SCNParticleSystem(named: "fire.scnp", inDirectory: nil)
        smokeNode.addParticleSystem(fire!)
    }
    
    @objc func longPressHandler(recognizer: UILongPressGestureRecognizer) {
        let sceneView = recognizer.view as! ARSCNView
        let touchLocation = recognizer.location(in: sceneView)
        
        let hitTestResults = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
        if !hitTestResults.isEmpty {
            guard let hitResult = hitTestResults.first else { return }
            print(hitResult.worldTransform.columns.3)
            addPlants(hitResult: hitResult)
        }
    }
    
    @objc func doubleTapHandler(recognizer: UITapGestureRecognizer) {
        let sceneView = recognizer.view as! ARSCNView
        let touch = recognizer.location(in: sceneView)
        
        let hitResults = sceneView.hitTest(touch, options: [:])
        if hitResults.isEmpty {
            guard let hitResult = hitResults.first else { return }
            let node = hitResult.node
            node.physicsBody?.applyForce(SCNVector3Make(20.0, hitResult.worldCoordinates.y, hitResult.worldCoordinates.z), asImpulse: true)
        }
    }
    
    @objc func singleTapHandler(recognizer: UITapGestureRecognizer) {
        if let sceneView = recognizer.view as? ARSCNView {
            let touchLocation = recognizer.location(in: sceneView)
            let hitTestResult = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
            
            if !hitTestResult.isEmpty {
                guard let hitResult = hitTestResult.first else { return }
                createDropOffBox(hitResult)
            } else {
                print("just touch touch touch in AR View")
            }
        }
        
        /**
         Cast as SCNView, for testing, tap the cube to change its color
        let sceneView = recognizer.view as! SCNView
        let touchLocation = recognizer.location(in: sceneView)
        let hitResults = sceneView.hitTest(touchLocation, options: [:])
        
        if !hitResults.isEmpty {
            let node = hitResults[0].node
            let material = node.geometry?.material(named: "Color")
            material?.diffuse.contents = UIColor.random()
        } else {
            print("just touch touch touch")
        }
         */
    }
    
    private func addPlants(hitResult: ARHitTestResult) {
        let plantScene = SCNScene(named: "art.scnassets/plants.dae")
        let plantNode = plantScene?.rootNode.childNode(withName: "SketchUp", recursively: true)
        plantNode?.position = SCNVector3Make(hitResult.worldTransform.columns.3.x,
                                             hitResult.worldTransform.columns.3.y,
                                             hitResult.worldTransform.columns.3.z)
        sceneView.scene.rootNode.addChildNode(plantNode!)
    }
    
    // MARK: - Create Objects
    private func createDropOffBox(_ hitResult: ARHitTestResult) {
        let offSet: Float = 0.5
        
        let boxGeometry = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.lightGray
        boxGeometry.materials = [material]
        
        let boxNode = SCNNode(geometry: boxGeometry)
        boxNode.name = "box"
        // Add physics
        boxNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: boxGeometry, options: [:]))
        boxNode.physicsBody?.mass = 2.0
        boxNode.physicsBody?.categoryBitMask = BodyType.box.rawValue
        
        boxNode.position = SCNVector3Make(hitResult.worldTransform.columns.3.x,
                                          hitResult.worldTransform.columns.3.y + offSet,
                                          hitResult.worldTransform.columns.3.z)
        sceneView.scene.rootNode.addChildNode(boxNode)
    }
    
    fileprivate func createSphereContent() -> SCNNode {
        let sphere = SCNSphere(radius: 0.4)
        
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: "earth")
        
        let node = SCNNode(geometry: sphere)
        node.position = SCNVector3(0.5, 0.5, -1.5)
        node.geometry?.materials = [material]
        
        // Customize: Make the earth rotate!
        let spin = CABasicAnimation(keyPath: "rotation")
        spin.fromValue = NSValue(scnVector4: SCNVector4Make(0, 1, 0, 0))
        spin.toValue = NSValue(scnVector4: SCNVector4Make(0, 1, 0, Float(Double.pi * 2)))
        spin.duration = 30
        spin.repeatCount = .infinity
        node.addAnimation(spin, forKey: "spin around")
        
        return node
    }
    
    fileprivate func createBoxContent() -> SCNNode {
        // Create an object
        let box = SCNBox(width: 0.2, height: 0.2, length: 0.2, chamferRadius: 0)
        
        // Create material
        let material = SCNMaterial()
        material.name = "Color"
        material.diffuse.contents = UIColor.blue
        
        // Create a node, in SceneKit, everything has to be put in a node
        // Then add to root node in order to display
        let node = SCNNode()
        node.geometry = box
        node.geometry?.materials = [material]
        node.position = SCNVector3(0, 0.1, -0.5)
        
        return node
    }
    
    fileprivate func createTextContent() -> SCNNode {
        let textGeometry = SCNText(string: "Hello Vincent", extrusionDepth: 1)
        textGeometry.firstMaterial?.diffuse.contents = UIColor.random() // Default color is white
        
        let textNode = SCNNode(geometry: textGeometry)
        textNode.position = SCNVector3(0, 0.3, -0.5)
        textNode.scale = SCNVector3(0.02, 0.02, 0.02)
        
        return textNode
    }
    
    fileprivate func createMissile() -> SCNNode {
        let missileScene = SCNScene(named: "art.scnassets/missile.scn")
        let missile = Missile(scene: missileScene!)
        missile.name = "missile"
        missile.position = SCNVector3Make(-3, 0, -10)
        return missile
    }
}

// MARK: - Scene view delegate
extension ViewController: ARSCNViewDelegate {
    // When ARKit found a plane, this delegate will be called
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if !(anchor is ARPlaneAnchor) { return }
        
        let plane = OverlayPlane(anchor: anchor as! ARPlaneAnchor)
        planes.append(plane)
        node.addChildNode(plane)
    }
    
    // When ARKit found a plane that appeared before and could be updated, this will be called
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        let plane = planes.filter{ $0.anchor.identifier == anchor.identifier }.first
        if plane == nil { return }
        plane?.update(anchor: anchor as! ARPlaneAnchor)
    }
}
