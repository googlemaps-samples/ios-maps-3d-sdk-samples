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

/// Pure mathematical utilities for spherical navigation, spline interpolation, and signal filtering.
public enum FlightMath {
  /// Mean Earth radius in meters.
  public static let earthRadiusMeters: Double = 6_371_000.0

  /// Conversion factor from nautical knots to meters per second.
  public static let metersPerSecondPerKnot: Double = 0.514444

  /// Converts degrees to radians.
  public static func degreesToRadians(_ degrees: Double) -> Double {
    degrees * .pi / 180.0
  }

  /// Converts radians to degrees.
  public static func radiansToDegrees(_ radians: Double) -> Double {
    radians * 180.0 / .pi
  }

  /// Clamps a value to the closed range `[minValue, maxValue]`.
  public static func clamp(_ value: Double, min minValue: Double, max maxValue: Double) -> Double {
    Swift.max(minValue, Swift.min(maxValue, value))
  }

  /// Normalizes a compass heading in degrees into `[0, 360)`.
  public static func normalizeHeading(_ degrees: Double) -> Double {
    let mod = degrees.truncatingRemainder(dividingBy: 360.0)
    return mod < 0 ? mod + 360.0 : mod
  }

  /// Computes the shortest signed angular difference `to - from` in degrees within `[-180, 180]`.
  public static func shortestAngleDelta(from startDegrees: Double, to endDegrees: Double) -> Double {
    var delta = (endDegrees - startDegrees).truncatingRemainder(dividingBy: 360.0)
    if delta > 180.0 {
      delta -= 360.0
    } else if delta < -180.0 {
      delta += 360.0
    }
    return delta
  }

  /// Evaluates a Catmull-Rom cubic spline at normalized parameter `u` in `[0, 1]` between `p1` and `p2`.
  public static func catmullRom(p0: Double, p1: Double, p2: Double, p3: Double, u: Double) -> Double {
    let u2 = u * u
    let u3 = u2 * u
    return 0.5 * (
      (2.0 * p1) +
      (-p0 + p2) * u +
      (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * u2 +
      (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * u3
    )
  }

  /// Evaluates cubic Hermite smoothstep `3u^2 - 2u^3` for `u` in `[0, 1]`.
  public static func smoothstep(_ u: Double) -> Double {
    let clamped = clamp(u, min: 0.0, max: 1.0)
    return clamped * clamped * (3.0 - 2.0 * clamped)
  }

  /// Computes the great-circle Haversine surface distance in meters between two geographic coordinates.
  public static func greatCircleDistanceMeters(
    lat1: Double,
    lon1: Double,
    lat2: Double,
    lon2: Double
  ) -> Double {
    let phi1 = degreesToRadians(lat1)
    let phi2 = degreesToRadians(lat2)
    let dPhi = degreesToRadians(lat2 - lat1)
    let dLambda = degreesToRadians(lon2 - lon1)

    let a = sin(dPhi * 0.5) * sin(dPhi * 0.5) +
      cos(phi1) * cos(phi2) * sin(dLambda * 0.5) * sin(dLambda * 0.5)
    let c = 2.0 * atan2(sqrt(a), sqrt(max(0.0, 1.0 - a)))
    return earthRadiusMeters * c
  }

  /// Calculates the initial forward azimuth (bearing in degrees `[0, 360)`) from one coordinate to another.
  public static func greatCircleBearingDegrees(
    lat1: Double,
    lon1: Double,
    lat2: Double,
    lon2: Double
  ) -> Double {
    let phi1 = degreesToRadians(lat1)
    let lambda1 = degreesToRadians(lon1)
    let phi2 = degreesToRadians(lat2)
    let lambda2 = degreesToRadians(lon2)

    let dLambda = lambda2 - lambda1
    let y = sin(dLambda) * cos(phi2)
    let x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(dLambda)
    let radians = atan2(y, x)
    return normalizeHeading(radiansToDegrees(radians))
  }

  /// Projects a starting coordinate along a forward bearing and distance over Earth's spherical surface.
  public static func projectCoordinate(
    latitude: Double,
    longitude: Double,
    bearingDegrees: Double,
    distanceMeters: Double
  ) -> (latitude: Double, longitude: Double) {
    let dOverR = distanceMeters / earthRadiusMeters
    let lat1 = degreesToRadians(latitude)
    let lon1 = degreesToRadians(longitude)
    let brg = degreesToRadians(bearingDegrees)

    let lat2 = asin(sin(lat1) * cos(dOverR) + cos(lat1) * sin(dOverR) * cos(brg))
    let lon2 = lon1 + atan2(
      sin(brg) * sin(dOverR) * cos(lat1),
      cos(dOverR) - sin(lat1) * sin(lat2)
    )

    return (
      latitude: radiansToDegrees(lat2),
      longitude: radiansToDegrees(lon2)
    )
  }

  /// Computes the vertical pitch/climb angle in degrees from an altitude change over a horizontal distance.
  public static func pitchAngleDegrees(deltaAltitude: Double, horizontalDistance: Double) -> Double {
    guard horizontalDistance > 1e-3 else { return 0.0 }
    return radiansToDegrees(atan2(deltaAltitude, horizontalDistance))
  }

  /// Applies a symmetric deadband around zero to suppress micro-tremor noise.
  public static func applyDeadband(_ value: Double, threshold: Double) -> Double {
    guard abs(value) >= threshold else { return 0.0 }
    return value > 0 ? (value - threshold) : (value + threshold)
  }

  /// Applies a first-order Exponential Moving Average (EMA) low-pass filter.
  public static func emaSmooth(current: Double, target: Double, alpha: Double) -> Double {
    current + alpha * (target - current)
  }
}

