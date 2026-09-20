import CoreMotion
import Foundation

final class MotionGuide: ObservableObject {
    @Published private(set) var heading: Double = 0
    @Published private(set) var isLevel = true
    @Published private(set) var isAvailable = true

    private let manager = CMMotionManager()
    private let queue = OperationQueue()

    func start() {
        guard manager.isDeviceMotionAvailable else {
            isAvailable = false
            return
        }
        manager.deviceMotionUpdateInterval = 0.1
        manager.startDeviceMotionUpdates(to: queue) { [weak self] motion, _ in
            guard let self, let motion else { return }
            let degrees = motion.attitude.yaw * 180 / .pi
            let pitch = abs(motion.attitude.pitch * 180 / .pi)
            DispatchQueue.main.async {
                self.heading = (degrees + 360).truncatingRemainder(dividingBy: 360)
                self.isLevel = pitch < 25 || pitch > 155
            }
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
    }
}