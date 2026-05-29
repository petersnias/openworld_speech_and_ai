import SwiftUI
import ARKit
import RealityKit

struct ARViewContainer: UIViewRepresentable {
    let npcSpeaker: NPCSpeaker

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.session.delegate = context.coordinator
        context.coordinator.arView = arView
        context.coordinator.npcSpeaker = npcSpeaker

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        // iPhone 14 Pro has LiDAR — use mesh reconstruction for accurate surface geometry
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        arView.session.run(config)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    // MARK: - Coordinator

    @MainActor
    class Coordinator: NSObject, ARSessionDelegate {
        weak var arView: ARView?
        var npcSpeaker: NPCSpeaker?
        private var npcPlaced = false

        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            guard !npcPlaced,
                  let _ = anchors.compactMap({ $0 as? ARPlaneAnchor })
                      .first(where: { $0.alignment == .horizontal }),
                  let arView,
                  let frame = session.currentFrame else { return }

            npcPlaced = true
            placeNPC(in: arView, cameraTransform: frame.camera.transform)
        }

        private func placeNPC(in arView: ARView, cameraTransform: simd_float4x4) {
            // Position NPC 1.5m directly in front of the camera at detection time
            var forward = matrix_identity_float4x4
            forward.columns.3.z = -1.5
            let worldTransform = cameraTransform * forward

            let anchor = AnchorEntity(world: worldTransform.translation)
            let npc = NPCEntity()
            anchor.addChild(npc)
            arView.scene.addAnchor(anchor)

            // NPC speaks the opening greeting after a short delay to let audio session settle
            Task {
                try? await Task.sleep(for: .milliseconds(600))
                npcSpeaker?.speak("Bonjour ! Vous avez l'air perdu. Puis-je vous aider ?")
            }
        }
    }
}

// MARK: - simd_float4x4 convenience

private extension simd_float4x4 {
    var translation: SIMD3<Float> {
        SIMD3<Float>(columns.3.x, columns.3.y, columns.3.z)
    }
}
