import SwiftUI
import ARKit
import RealityKit

struct ARViewContainer: UIViewRepresentable {
    let onNPCPlaced: () -> Void
    let npcIsSpeaking: Bool

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.session.delegate = context.coordinator
        context.coordinator.arView = arView
        context.coordinator.onNPCPlaced = onNPCPlaced

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        // iPhone 14 Pro has LiDAR — use mesh reconstruction for accurate surface geometry
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        arView.session.run(config)

        return arView
    }

    // Called by SwiftUI whenever npcIsSpeaking changes — forward to Coordinator.
    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.updateSpeakingState(npcIsSpeaking)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    // MARK: - Coordinator

    @MainActor
    class Coordinator: NSObject, ARSessionDelegate {
        weak var arView: ARView?
        var onNPCPlaced: (() -> Void)?
        private var npcEntity: NPCEntity?
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
            npcEntity = npc
            anchor.addChild(npc)
            arView.scene.addAnchor(anchor)

            // Brief delay so the audio session settles before the first TTS utterance.
            Task {
                try? await Task.sleep(for: .milliseconds(600))
                onNPCPlaced?()
            }
        }

        func updateSpeakingState(_ isSpeaking: Bool) {
            if isSpeaking {
                npcEntity?.startTalkingAnimation()
            } else {
                npcEntity?.stopTalkingAnimation()
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
