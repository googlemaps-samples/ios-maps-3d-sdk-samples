// Copyright 2026 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation
import GoogleMaps3D
import Observation

/// Coordinates the flight simulator session lifecycle, countdown task, sensor streaming, and physics state.
@Observable
@MainActor
public final class FlightSession {
  public let motionManager = FlightMotionManager()

  // Flight configuration & state
  public var selectedPreset: FlightLocationPreset = .grandCanyon
  public var airspeedKnots: Double = 140.0
  public var isFlying: Bool = false

  // Countdown state
  public var countdownValue: Int = 0
  public var countdownText: String = ""
  private var countdownTask: Task<Void, Never>?

  // Aircraft physics & camera state
  public var aircraftState: AircraftState = AircraftState(preset: .grandCanyon)
  public var camera: Camera = FlightCameraRig.initialFPVCamera(for: .grandCanyon)

  // Manual fallback controls for Simulator testing
  public var manualPitch: Double = 0.0
  public var manualRoll: Double = 0.0

  // Frame clock tracking
  private var lastFrameDate: Date?

  public init() {}

  public var isMotionAvailable: Bool {
    motionManager.isMotionAvailable
  }

  public var currentPitch: Double {
    isMotionAvailable ? aircraftState.pitchDegrees : manualPitch
  }

  public var currentRoll: Double {
    isMotionAvailable ? aircraftState.rollDegrees : manualRoll
  }

  /// Warms up CoreMotion when the simulator view appears so sensor samples are ready for calibration.
  public func prepareSensors() {
    motionManager.startMotionUpdates()
  }

  /// Calibrates level and runs a cancellable 3-2-1 countdown before flight.
  public func startFlightWithCountdown() {
    countdownTask?.cancel()
    isFlying = false

    motionManager.startMotionUpdates()
    motionManager.calibrateZeroLevel()

    countdownTask = Task { @MainActor in
      for n in stride(from: 3, through: 1, by: -1) {
        self.countdownValue = n
        self.countdownText = "\(n)"
        try? await Task.sleep(for: .seconds(1))
        guard !Task.isCancelled else { return }
      }

      // Calibrate again right as flight begins so the user's posture at "FLY!" is level
      self.motionManager.calibrateZeroLevel()
      self.countdownValue = 0
      self.countdownText = "FLY!"
      self.lastFrameDate = .now
      self.isFlying = true

      try? await Task.sleep(for: .milliseconds(600))
      guard !Task.isCancelled else { return }
      self.countdownText = ""
    }
  }

  /// Pauses active flight.
  public func pauseFlight() {
    countdownTask?.cancel()
    countdownTask = nil
    countdownValue = 0
    countdownText = ""
    isFlying = false
    lastFrameDate = nil
  }

  /// Resets the aircraft and camera to the specified regional preset.
  public func resetToPreset(_ preset: FlightLocationPreset) {
    pauseFlight()
    selectedPreset = preset
    aircraftState = AircraftState(preset: preset)
    camera = FlightCameraRig.initialFPVCamera(for: preset)
  }

  /// Zeroes out the motion sensors at the user's current handheld angle.
  public func calibrateLevel() {
    motionManager.calibrateZeroLevel()
  }

  /// Stops all active tasks and sensor updates when the view disappears.
  public func stop() {
    pauseFlight()
    motionManager.stopMotionUpdates()
  }

  /// Advances flight physics and updates the FPV camera on each `TimelineView` frame tick.
  public func tick(at currentDate: Date) {
    guard isFlying else { return }

    let dt = currentDate.timeIntervalSince(lastFrameDate ?? currentDate)
    lastFrameDate = currentDate
    guard dt > 0 && dt < 0.25 else { return }

    let livePitch = isMotionAvailable ? motionManager.filteredPitch : manualPitch
    let liveRoll = isMotionAvailable ? motionManager.filteredRoll : manualRoll

    let input = ControlInput(
      pitchDegrees: livePitch,
      rollDegrees: liveRoll,
      airspeedKnots: airspeedKnots
    )
    aircraftState.integrate(dt: dt, input: input, preset: selectedPreset)
    camera = FlightCameraRig.fpvCamera(for: aircraftState)
  }
}
