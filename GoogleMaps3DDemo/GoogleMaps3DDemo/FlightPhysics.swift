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

/// Preset scenic locations featuring 3D topography and urban structures.
public enum FlightLocationPreset: String, CaseIterable, Identifiable, Sendable {
  case grandCanyon = "Grand Canyon"
  case sanFrancisco = "San Francisco"
  case alpsInnsbruck = "Innsbruck Alps"
  case newYork = "New York City"

  public var id: String { rawValue }

  /// Initial flight location in Mean Sea Level (MSL) altitude.
  public var initialLocation: LatLngAltitude {
    switch self {
    case .grandCanyon:
      return LatLngAltitude(latitude: 36.0946, longitude: -111.8435, altitude: 2400.0)
    case .sanFrancisco:
      return LatLngAltitude(latitude: 37.7958, longitude: -122.3950, altitude: 450.0)
    case .alpsInnsbruck:
      return LatLngAltitude(latitude: 47.2630, longitude: 11.3704, altitude: 1800.0)
    case .newYork:
      return LatLngAltitude(latitude: 40.7050, longitude: -74.0090, altitude: 450.0)
    }
  }

  public var initialHeading: Double {
    switch self {
    case .grandCanyon: return 185.0
    case .sanFrancisco: return 288.0
    case .alpsInnsbruck: return 240.0
    case .newYork: return 30.0
    }
  }

  /// Minimum Mean Sea Level (MSL) altitude floor for the preset flight envelope.
  public var minFloorAltitude: Double {
    switch self {
    case .grandCanyon: return 1100.0
    case .sanFrancisco: return 120.0
    case .alpsInnsbruck: return 850.0
    case .newYork: return 150.0
    }
  }

  /// Maximum Mean Sea Level (MSL) altitude ceiling for the preset flight envelope.
  public var maxCeilingAltitude: Double {
    switch self {
    case .grandCanyon: return 6000.0
    case .sanFrancisco: return 3500.0
    case .alpsInnsbruck: return 6000.0
    case .newYork: return 3500.0
    }
  }
}

/// Instantaneous pilot control inputs for a single simulation step.
public struct ControlInput: Sendable {
  public var pitchDegrees: Double
  public var rollDegrees: Double
  public var airspeedKnots: Double

  public init(pitchDegrees: Double = 0.0, rollDegrees: Double = 0.0, airspeedKnots: Double = 140.0) {
    self.pitchDegrees = pitchDegrees
    self.rollDegrees = rollDegrees
    self.airspeedKnots = airspeedKnots
  }
}

/// Mutable kinematic state of the simulated aircraft.
public struct AircraftState {
  public var position: LatLngAltitude
  public var heading: Double
  public var verticalSpeedMps: Double
  public var pitchDegrees: Double
  public var rollDegrees: Double

  public init(preset: FlightLocationPreset) {
    self.position = preset.initialLocation
    self.heading = preset.initialHeading
    self.verticalSpeedMps = 0.0
    self.pitchDegrees = 0.0
    self.rollDegrees = 0.0
  }

  /// Integrates aircraft kinematics forward by `dt` seconds given the current control input.
  public mutating func integrate(
    dt: Double,
    input: ControlInput,
    preset: FlightLocationPreset
  ) {
    guard dt > 0 && dt < 0.25 else { return }

    self.pitchDegrees = input.pitchDegrees
    self.rollDegrees = input.rollDegrees

    // 1. Coordinated turn rate from bank angle: yawRate = bankAngle * 0.75 deg/sec
    let yawRate = input.rollDegrees * 0.75
    self.heading = FlightMath.normalizeHeading(self.heading + yawRate * dt)

    // 2. Airspeed (knots to meters per second)
    let speedMps = input.airspeedKnots * FlightMath.metersPerSecondPerKnot

    // 3. Vertical speed (climb when pitch > 0, dive when pitch < 0)
    let climbAngleRad = FlightMath.degreesToRadians(input.pitchDegrees)
    self.verticalSpeedMps = speedMps * sin(climbAngleRad)

    // 4. Regional MSL floor & ceiling envelope clamping
    let rawAlt = self.position.altitude + self.verticalSpeedMps * dt
    let clampedAlt = FlightMath.clamp(
      rawAlt,
      min: preset.minFloorAltitude,
      max: preset.maxCeilingAltitude
    )

    // 5. Horizontal distance traveled & spherical coordinate integration
    let horizontalSpeedMps = speedMps * cos(climbAngleRad)
    let distanceMeters = horizontalSpeedMps * dt

    let projected = FlightMath.projectCoordinate(
      latitude: self.position.latitude,
      longitude: self.position.longitude,
      bearingDegrees: self.heading,
      distanceMeters: distanceMeters
    )

    self.position = LatLngAltitude(
      latitude: projected.latitude,
      longitude: projected.longitude,
      altitude: clampedAlt
    )
  }
}
