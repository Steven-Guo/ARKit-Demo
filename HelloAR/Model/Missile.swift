//
//  Missile.swift
//  HelloAR
//
//  Created by Minxin Guo on 7/3/17.
//  Copyright © 2017 Minxin Guo. All rights reserved.
//

import Foundation
import SceneKit
import ARKit

class Missile: SCNNode {
    
    private var scene: SCNScene!
    
    init(scene: SCNScene) {
        super.init()
        self.scene = scene
        setup()
    }
    
    init(missileNode: SCNNode) {
        super.init()
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func setup() {
        guard let missileNode = self.scene.rootNode.childNode(withName: "missileNode", recursively: true),
            let smokeNode = self.scene.rootNode.childNode(withName: "smokeNode", recursively: true) else {
                fatalError("Nodes not found")
        }
        let smoke = SCNParticleSystem(named: "smoke.scnp", inDirectory: nil)
        smokeNode.addParticleSystem(smoke!)
        
        self.addChildNode(missileNode)
        self.addChildNode(smokeNode)
    }
}
