import AVFoundation

/// Configures AVAudioSession for simultaneous mic capture and speaker playback.
/// Prefers AirPods mic when connected; re-routes automatically on Bluetooth reconnect.
final class AudioSessionManager {
    static let shared = AudioSessionManager()

    private init() {}

    func configure() {
        let session = AVAudioSession.sharedInstance()
        do {
            // .allowBluetooth routes mic input through AirPods HFP profile
            // .allowBluetoothA2DP routes speaker output through AirPods high-quality profile
            try session.setCategory(
                .playAndRecord,
                mode: .default,
                options: [.allowBluetooth, .allowBluetoothA2DP, .defaultToSpeaker]
            )
            try session.setActive(true)
        } catch {
            print("[AudioSessionManager] Setup failed: \(error)")
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(routeDidChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )

        preferBluetoothInputIfAvailable()
    }

    @objc private func routeDidChange(_ note: Notification) {
        guard let rawReason = note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: rawReason) else { return }
        switch reason {
        case .newDeviceAvailable, .oldDeviceUnavailable:
            preferBluetoothInputIfAvailable()
        default:
            break
        }
    }

    private func preferBluetoothInputIfAvailable() {
        let session = AVAudioSession.sharedInstance()
        guard let btInput = session.availableInputs?.first(where: {
            $0.portType == .bluetoothHFP || $0.portType == .bluetoothLE
        }) else { return }
        try? session.setPreferredInput(btInput)
    }
}
