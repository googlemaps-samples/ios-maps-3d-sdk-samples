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

/// Supported camera perspectives for flight trajectory playback and simulation.
public enum FlightCameraMode: String, CaseIterable, Identifiable, Sendable {
  case chase = "Chase (Following)"
  case topDown = "Top-Down"

  public var id: String { rawValue }
}

/// Camera policy builder for FPV cockpit, 3rd-person chase, and top-down perspectives.
public enum FlightCameraRig {
  /// Constructs a first-person cockpit camera for the flight simulator.
  ///
  /// - Positive `pitchDegrees` (pulling back / climbing) increases `tilt` toward the horizon (looking up).
  /// - Negative `pitchDegrees` (pushing forward / diving) decreases `tilt` toward the ground (looking down).
  /// - Positive `rollDegrees` (tilting right) banks the camera right (`+roll`) into the turn.
  public static func fpvCamera(for state: AircraftState) -> Camera {
    let boundedTilt = FlightMath.clamp(75.0 + state.pitchDegrees * 0.65, min: 40.0, max: 86.0)
    return Camera(
      center: state.position,
      heading: state.heading,
      tilt: boundedTilt,
      roll: state.rollDegrees * 0.5,
      range: 50.0
    )
  }

  /// Constructs the initial FPV camera for a location preset.
  public static func initialFPVCamera(for preset: FlightLocationPreset) -> Camera {
    Camera(
      center: preset.initialLocation,
      heading: preset.initialHeading,
      tilt: 75.0,
      roll: 0.0,
      range: 50.0
    )
  }

  /// Constructs a chase or top-down camera centered directly on the aircraft's position.
  public static func routeCamera(
    mode: FlightCameraMode,
    position: LatLngAltitude,
    heading: Double,
    altitudeMode: AltitudeMode = .absolute
  ) -> Camera {
    switch mode {
    case .chase:
      return Camera(
        center: position,
        heading: heading,
        tilt: 75.0,
        roll: 0.0,
        range: 750.0,
        altitudeMode: altitudeMode
      )
    case .topDown:
      return Camera(
        center: position,
        heading: heading,
        tilt: 0.0,
        roll: 0.0,
        range: 1500.0,
        altitudeMode: altitudeMode
      )
    }
  }
}
