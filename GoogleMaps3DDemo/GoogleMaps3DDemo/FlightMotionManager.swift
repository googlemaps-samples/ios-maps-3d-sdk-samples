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

import CoreMotion
import Foundation
import UIKit

/// Manages CoreMotion sensor streaming with tare calibration, deadband filtering, and EMA smoothing.
///
/// Sensor samples are stored as plain properties (without `@Published`) so CoreMotion's 60Hz callback
/// does not invalidate SwiftUI views outside the `TimelineView` frame clock.
@MainActor
public final class FlightMotionManager {
  private let motionManager = CMMotionManager()

  /// Filtered pitch angle in degrees (positive = pull back / climb / look up, negative = push forward / dive / look down).
  public private(set) var filteredPitch: Double = 0.0

  /// Filtered bank/roll angle in degrees (positive = tilt right / bank right, negative = tilt left / bank left).
  public private(set) var filteredRoll: Double = 0.0

  /// Whether device motion hardware is available on this device.
  public var isMotionAvailable: Bool {
    motionManager.isDeviceMotionAvailable
  }

  // Calibration offsets (tare reference)
  private var pitchOffset: Double = 0.0
  private var rollOffset: Double = 0.0
  private var needsCalibration: Bool = true

  // Filter tuning parameters
  private let smoothingFactor: Double = 0.25
  private let deadbandDegrees: Double = 1.5
  private let maxPitchDegrees: Double = 45.0
  private let maxRollDegrees: Double = 60.0

  public init() {}

  deinit {
    motionManager.stopDeviceMotionUpdates()
  }

  /// Starts 60Hz device motion streaming.
  public func startMotionUpdates() {
    guard motionManager.isDeviceMotionAvailable, !motionManager.isDeviceMotionActive else {
      return
    }

    motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
    motionManager.startDeviceMotionUpdates(
      using: .xArbitraryZVertical,
      to: .main
    ) { [weak self] motion, _ in
      guard let self, let motion else { return }
      self.processMotion(motion)
    }
  }

  /// Stops sensor updates when the view disappears.
  public func stopMotionUpdates() {
    motionManager.stopDeviceMotionUpdates()
  }

  /// Sets the current handheld orientation as the neutral (level flight) baseline.
  public func calibrateZeroLevel() {
    if let motion = motionManager.deviceMotion {
      let rawAngles = extractAngles(from: motion.gravity)
      pitchOffset = rawAngles.pitch
      rollOffset = rawAngles.roll
      needsCalibration = false
    } else {
      needsCalibration = true
    }
    filteredPitch = 0.0
    filteredRoll = 0.0
  }

  /// Processes raw CoreMotion gravity into smoothed, calibrated flight control angles.
  private func processMotion(_ motion: CMDeviceMotion) {
    let raw = extractAngles(from: motion.gravity)

    if needsCalibration {
      pitchOffset = raw.pitch
      rollOffset = raw.roll
      needsCalibration = false
    }

    // 1. Apply calibration tare using shortest angular delta so wrapping across ±180° never jumps
    let calibratedPitch = FlightMath.shortestAngleDelta(from: pitchOffset, to: raw.pitch)
    let calibratedRoll = FlightMath.shortestAngleDelta(from: rollOffset, to: raw.roll)

    // 2. Apply deadband filter to eliminate micro hand tremor jitter
    let deadbandedPitch = FlightMath.applyDeadband(calibratedPitch, threshold: deadbandDegrees)
    let deadbandedRoll = FlightMath.applyDeadband(calibratedRoll, threshold: deadbandDegrees)

    // 3. Clamp to safe flight envelope
    let clampedPitch = FlightMath.clamp(deadbandedPitch, min: -maxPitchDegrees, max: maxPitchDegrees)
    let clampedRoll = FlightMath.clamp(deadbandedRoll, min: -maxRollDegrees, max: maxRollDegrees)

    // 4. Low-pass exponential moving average (EMA) filter
    filteredPitch = FlightMath.emaSmooth(
      current: filteredPitch,
      target: clampedPitch,
      alpha: smoothingFactor
    )
    filteredRoll = FlightMath.emaSmooth(
      current: filteredRoll,
      target: clampedRoll,
      alpha: smoothingFactor
    )
  }

  /// Extracts screen-aligned pitch and roll angles from the gravity vector across all interface orientations:
  /// - Pulling the top edge back toward the user -> positive `pitch` (climb / look up).
  /// - Tipping the top edge forward away from the user -> negative `pitch` (dive / look down).
  /// - Tilting the right side down -> positive `roll` (bank right / turn right).
  /// - Tilting the left side down -> negative `roll` (bank left / turn left).
  private func extractAngles(from g: CMAcceleration) -> (pitch: Double, roll: Double) {
    let orientation = currentInterfaceOrientation()
    let sx: Double
    let sy: Double
    let sz = g.z

    switch orientation {
    case .landscapeRight:
      // UIInterfaceOrientation.landscapeRight: device top on left, USB-C on right
      sx = -g.y
      sy = g.x
    case .landscapeLeft:
      // UIInterfaceOrientation.landscapeLeft: device top on right, USB-C on left
      sx = g.y
      sy = -g.x
    case .portraitUpsideDown:
      sx = -g.x
      sy = -g.y
    default:
      // Portrait: device top at top, right edge at right
      sx = g.x
      sy = g.y
    }

    // In screen coordinates (sx right, sy up, sz out of screen toward user):
    // Pulling top edge back increases -sy relative to -sz -> positive pitch (climb / look up).
    // Tipping top edge forward decreases -sy relative to -sz -> negative pitch (dive / look down).
    let pitch = atan2(-sy, -sz) * 180.0 / .pi

    // Tilting right hand down increases +sx -> positive roll (bank right into turn).
    // Using hypot(sy, sz) keeps roll sensitive across all holding angles from flat to vertical.
    let roll = atan2(sx, hypot(sy, sz)) * 180.0 / .pi

    return (pitch, roll)
  }

  private func currentInterfaceOrientation() -> UIInterfaceOrientation {
    let scenes = UIApplication.shared.connectedScenes
    for scene in scenes {
      if let windowScene = scene as? UIWindowScene {
        return windowScene.interfaceOrientation
      }
    }
    return .portrait
  }
}
