//
//  DotGridView.swift
//  Letterpress
//
//  Created by Rachel on 9/6/2025.
//

import SwiftUI
#if os(iOS)
import CoreMotion
#endif

struct DotPosition: Equatable, Hashable {
    let row: Int
    let column: Int
}

struct DotGridView: View {
    @StateObject private var motion = DeviceTiltProvider()

    static let rows = 101
    static let columns = 101
    static let spacing = 12.0
    static let centerRow = 50
    static let centerColumn = 50
    static let gridWidth = spacing * CGFloat(columns - 1)
    static let gridHeight = spacing * CGFloat(rows - 1)

    var body: some View {
        GeometryReader { geometry in
            let startX = (geometry.size.width - Self.gridWidth) / 2
            let startY = (geometry.size.height - Self.gridHeight) / 2
            let tilt = motion.tilt

            ZStack {
                Color.black

                HStack(spacing: 8) {
                    Image("DotGrid")
                        .renderingMode(.original)
                        .resizable(resizingMode: .tile)
                        .scaleEffect(x: -1, y: 1)

                    Image("DotGrid")
                        .renderingMode(.original)
                        .resizable(resizingMode: .tile)
                }

                Text(verbatim: "Letterpress")
                    .font(.custom("ChillBitmapSE", size: 32))
                    .foregroundColor(.white)
                    .position(
                        x: startX + CGFloat(Self.centerColumn) * Self.spacing,
                        y: startY + CGFloat(Self.centerRow) * Self.spacing - 60.0
                    )
                    .modifier(DepthTiltEffect(tilt: tilt))

                Text(verbatim: "OwnGoal Studio")
                    .font(.custom("ChillBitmapSE", size: 32))
                    .foregroundColor(.white)
                    .position(
                        x: startX + CGFloat(Self.centerColumn) * Self.spacing,
                        y: startY + CGFloat(Self.centerRow) * Self.spacing + 60.0
                    )
                    .modifier(DepthTiltEffect(tilt: tilt))
            }
            .contentShape(Rectangle())
            .onAppear { motion.start() }
            .onDisappear { motion.stop() }
        }
    }
}

private struct DepthTiltEffect: ViewModifier {
    let tilt: DeviceTiltProvider.Tilt
    private let maxAngle = 10.0
    private let perspective = 0.4
    private let scaleFactor = 0.1

    func body(content: Content) -> some View {
        let clampedPitch = tilt.pitch.clamped(to: -maxAngle...maxAngle) * scaleFactor
        let clampedRoll = tilt.roll.clamped(to: -maxAngle...maxAngle) * scaleFactor

        return content
            .rotation3DEffect(
                .degrees(clampedPitch),
                axis: (x: 1, y: 0, z: 0),
                anchor: .center,
                perspective: perspective
            )
            .rotation3DEffect(
                .degrees(-clampedRoll),
                axis: (x: 0, y: 1, z: 0),
                anchor: .center,
                perspective: perspective
            )
            .offset(
                x: CGFloat(clampedRoll * 1.6),
                y: CGFloat(-clampedPitch * 1.6)
            )
    }
}

private final class DeviceTiltProvider: ObservableObject {
    struct Tilt {
        let pitch: Double
        let roll: Double

        static let zero = Tilt(pitch: 0, roll: 0)
    }

    @Published private(set) var tilt = Tilt.zero
    private var baselineTilt: Tilt?

#if os(iOS)
    private let motionManager = CMMotionManager()
    private let queue: OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService = .userInteractive
        queue.name = "DeviceTiltProvider"
        return queue
    }()
#endif

    init() {
#if os(iOS)
        motionManager.deviceMotionUpdateInterval = 1.0 / 120.0
#endif
    }

    func start() {
#if os(iOS)
        guard motionManager.isDeviceMotionAvailable, motionManager.isDeviceMotionActive == false else { return }
        baselineTilt = nil
        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: queue) { [weak self] motion, _ in
            guard let data = motion else { return }
            let pitch = data.attitude.pitch.toDegrees()
            let roll = data.attitude.roll.toDegrees()
            DispatchQueue.main.async {
                self?.updateTilt(pitch: pitch, roll: roll)
            }
        }
#endif
    }

    func stop() {
#if os(iOS)
        guard motionManager.isDeviceMotionActive else { return }
        motionManager.stopDeviceMotionUpdates()
#endif
    }

    private func updateTilt(pitch: Double, roll: Double) {
        if baselineTilt == nil {
            baselineTilt = Tilt(pitch: pitch, roll: roll)
            tilt = .zero
            return
        }

        guard let baseline = baselineTilt else { return }

        let normalized = Tilt(
            pitch: pitch - baseline.pitch,
            roll: roll - baseline.roll
        )

        tilt = normalized
    }
}

private extension Double {
    func toDegrees() -> Double { self * 180 / .pi }

    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
