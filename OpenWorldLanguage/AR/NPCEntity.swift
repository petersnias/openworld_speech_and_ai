import RealityKit
import UIKit

/// Placeholder NPC — a blue rounded box standing ~0.5m tall.
/// Will be replaced with an animated USDZ avatar in Phase 1.
class NPCEntity: Entity {
    required init() {
        super.init()
        let mesh = MeshResource.generateBox(size: SIMD3<Float>(0.25, 0.5, 0.15), cornerRadius: 0.04)
        let material = SimpleMaterial(color: UIColor.systemBlue, roughness: 0.6, isMetallic: false)
        components.set(ModelComponent(mesh: mesh, materials: [material]))
        // Lift the box so its base sits on the detected surface
        position.y = 0.25
    }
}
