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
import SwiftUI

/// Manages CoreMotion sensor streaming with filtering, tare calibration, and deadband handling.
@MainActor
public class FlightMotionManager: ObservableObject {
  private let motionManager = CMMotionManager()

  /// Filtered pitch angle in degrees (positive = nose up / climb, negative = nose down / dive)
  @Published public var filteredPitch: Double = 0.0

  /// Filtered bank/roll angle in degrees (positive = bank right, negative = bank left)
  @Published public var filteredRoll: Double = 0.0

  /// Whether device motion hardware is active and available
  @Published public var isMotionAvailable: Bool = false

  // Calibration offsets (tare reference)
  private var pitchOffset: Double = 0.0
  private var rollOffset: Double = 0.0

  // Filter tuning parameters
  private let smoothingFactor: Double = 0.22 // Exponential Moving Average (EMA) alpha
  private let deadbandDegrees: Double = 2.0   // Ignore hand tremors under 2 degrees
  private let maxPitchDegrees: Double = 45.0  // Clamp max pitch
  private let maxRollDegrees: Double = 60.0   // Clamp max bank angle

  public init() {
    startMotionUpdates()
  }

  deinit {
    motionManager.stopDeviceMotionUpdates()
  }

  /// Starts 60Hz device motion streaming using the Z-vertical attitude reference frame.
  public func startMotionUpdates() {
    guard motionManager.isDeviceMotionAvailable else {
      isMotionAvailable = false
      return
    }

    isMotionAvailable = true
    motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
    motionManager.showsDeviceMovementDisplay = true

    motionManager.startDeviceMotionUpdates(
      using: .xArbitraryZVertical,
      to: .main
    ) { [weak self] motion, _ in
      guard let self = self, let motion = motion else { return }
      self.processMotion(motion)
    }
  }

  /// Stops sensor updates to conserve battery.
  public func stopMotionUpdates() {
    motionManager.stopDeviceMotionUpdates()
  }

  /// Sets the current handheld orientation as the neutral (level flight) baseline.
  public func calibrateZeroLevel() {
    guard let attitude = motionManager.deviceMotion?.attitude else { return }
    let rawAngles = extractLandscapeAngles(from: attitude)
    self.pitchOffset = rawAngles.pitch
    self.rollOffset = rawAngles.roll
    self.filteredPitch = 0.0
    self.filteredRoll = 0.0
  }

  /// Processes raw CoreMotion attitude into smoothed, calibrated flight control signals.
  private func processMotion(_ motion: CMDeviceMotion) {
    let raw = extractLandscapeAngles(from: motion.attitude)

    // 1. Apply calibration tare (subtract neutral grip baseline)
    let calibratedPitch = raw.pitch - pitchOffset
    let calibratedRoll = raw.roll - rollOffset

    // 2. Apply deadband filter to eliminate micro hand tremor jitter
    let deadbandedPitch = applyDeadband(calibratedPitch, threshold: deadbandDegrees)
    let deadbandedRoll = applyDeadband(calibratedRoll, threshold: deadbandDegrees)

    // 3. Clamp to safe flight envelope
    let clampedPitch = max(-maxPitchDegrees, min(maxPitchDegrees, deadbandedPitch))
    let clampedRoll = max(-maxRollDegrees, min(maxRollDegrees, deadbandedRoll))

    // 4. Low-pass exponential moving average (EMA) filter
    self.filteredPitch = self.filteredPitch + smoothingFactor * (clampedPitch - self.filteredPitch)
    self.filteredRoll = self.filteredRoll + smoothingFactor * (clampedRoll - self.filteredRoll)
  }

  /// Extracts pitch and roll angles adapted for holding the device in Landscape mode like a flight yoke.
  private func extractLandscapeAngles(from attitude: CMAttitude) -> (pitch: Double, roll: Double) {
    // In landscape orientation (holding phone horizontally with two hands):
    // Tilting top edge towards user -> positive pitch (Pull back to climb)
    // Tilting top edge away from user -> negative pitch (Push forward to dive)
    // Tilting right hand down -> positive roll (Bank right to turn right)
    // Tilting left hand down -> negative roll (Bank left to turn left)
    let pitchDeg = -attitude.roll * (180.0 / .pi)
    let rollDeg = attitude.pitch * (180.0 / .pi)
    return (pitchDeg, rollDeg)
  }

  private func applyDeadband(_ value: Double, threshold: Double) -> Double {
    if abs(value) < threshold {
      return 0.0
    }
    return value > 0 ? (value - threshold) : (value + threshold)
  }

  /// Manual override for Simulator testing where hardware sensors are unavailable.
  public func setManualInputs(pitch: Double, roll: Double) {
    self.filteredPitch = pitch
    self.filteredRoll = roll
  }
}
