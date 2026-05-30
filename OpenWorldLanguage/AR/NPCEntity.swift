import RealityKit
import UIKit

/// The NPC character placed in the AR scene.
/// Loads `npc_character.usdz` from the app bundle when available;
/// falls back to the blue-box placeholder so builds succeed without the asset.
class NPCEntity: Entity {

    private var talkingController: AnimationPlaybackController?

    required init() {
        super.init()

        if let loaded = try? Entity.load(named: "npc_character") {
            addChild(loaded)
            // Most humanoid USDZ assets have their origin at the feet, so no Y offset needed.
            position.y = 0
        } else {
            // Fallback: blue rounded box
            let mesh = MeshResource.generateBox(size: SIMD3<Float>(0.25, 0.5, 0.15), cornerRadius: 0.04)
            let material = SimpleMaterial(color: UIColor.systemBlue, roughness: 0.6, isMetallic: false)
            components.set(ModelComponent(mesh: mesh, materials: [material]))
            position.y = 0.25
        }
    }

    // MARK: - Talking animation

    /// Plays a subtle scale pulse while the NPC is speaking.
    /// If the USDZ has embedded animations, those fire automatically through RealityKit;
    /// this adds a scale oscillation as a universal fallback.
    func startTalkingAnimation() {
        guard talkingController == nil else { return }

        let restScale = transform.scale
        let peakScale = restScale * 1.025

        let grow = FromToByAnimation<Transform>(
            name: "talk_grow",
            from: Transform(scale: restScale),
            to: Transform(scale: peakScale),
            duration: 0.25,
            timing: .easeInOut,
            bindTarget: .transform
        )
        let shrink = FromToByAnimation<Transform>(
            name: "talk_shrink",
            from: Transform(scale: peakScale),
            to: Transform(scale: restScale),
            duration: 0.25,
            timing: .easeInOut,
            bindTarget: .transform
        )

        if let growAnim = try? AnimationResource.generate(with: grow),
           let shrinkAnim = try? AnimationResource.generate(with: shrink) {
            let sequence = try? AnimationResource.sequence(with: [growAnim, shrinkAnim])
            talkingController = sequence.map { playAnimation($0.repeat()) }
        }
    }

    func stopTalkingAnimation() {
        talkingController?.stop()
        talkingController = nil
        // Snap back to identity scale in case the animation left it mid-pulse.
        move(to: Transform(scale: .one), relativeTo: parent, duration: 0.15)
    }
}
