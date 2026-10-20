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

import CoreLocation
import Foundation
import GoogleMaps3D

/// Non-SDK utility for calculating path distances, interpolating coordinates at constant speeds,
/// and computing forward look-ahead bearings for smooth camera corner anticipation.
public struct PathMetadata {
  public let points: [LatLngAltitude]
  public let distances: [Double]
  public let segmentBearings: [Double]
  public let totalLength: Double

  /// Initializes path metadata by pre-computing cumulative geodesic distances and segment bearings.
  ///
  /// If two consecutive waypoints are identical (`segmentLength < 1e-6`), the previous segment's
  /// bearing is preserved to prevent heading snaps to 0° (North).
  public init(path: [LatLngAltitude]) {
    self.points = path
    var dists: [Double] = [0.0]
    var bearings: [Double] = []
    var total: Double = 0.0
    var lastValidBearing: Double = 0.0

    if path.count > 1 {
      for i in 0..<(path.count - 1) {
        let p1 = CLLocation(latitude: path[i].latitude, longitude: path[i].longitude)
        let p2 = CLLocation(latitude: path[i + 1].latitude, longitude: path[i + 1].longitude)
        let segDist = p1.distance(from: p2)
        total += segDist
        dists.append(total)

        if segDist >= 1e-6 {
          lastValidBearing = Self.calculateBearing(from: path[i], to: path[i + 1])
        }
        bearings.append(lastValidBearing)
      }
    }

    self.distances = dists
    self.segmentBearings = bearings
    self.totalLength = max(total, 1.0)
  }

  /// Interpolates a `LatLngAltitude` coordinate at a given distance along the path.
  public func position(at distance: Double, altitudeOffset: Double = 0.0) -> LatLngAltitude {
    guard points.count > 1 else {
      return points.first ?? .init(latitude: 0, longitude: 0, altitude: altitudeOffset)
    }

    let clampedDist = max(0, min(distance, totalLength))

    for i in 0..<(distances.count - 1) {
      let dStart = distances[i]
      let dEnd = distances[i + 1]

      if clampedDist >= dStart && clampedDist <= dEnd {
        let segmentDist = dEnd - dStart
        let t = segmentDist > 1e-6 ? (clampedDist - dStart) / segmentDist : 0.0
        let p1 = points[i]
        let p2 = points[i + 1]

        let lat = p1.latitude + (p2.latitude - p1.latitude) * t
        let lon = p1.longitude + (p2.longitude - p1.longitude) * t
        let alt = p1.altitude + (p2.altitude - p1.altitude) * t + altitudeOffset

        return LatLngAltitude(latitude: lat, longitude: lon, altitude: alt)
      }
    }

    let last = points[points.count - 1]
    return LatLngAltitude(
      latitude: last.latitude,
      longitude: last.longitude,
      altitude: last.altitude + altitudeOffset
    )
  }

  /// Returns the pre-computed segment bearing at a given distance along the path.
  public func segmentBearing(at distance: Double) -> Double {
    guard !segmentBearings.isEmpty else { return 0.0 }
    let clampedDist = max(0, min(distance, totalLength))

    for i in 0..<(distances.count - 1) {
      if clampedDist >= distances[i] && clampedDist <= distances[i + 1] {
        return segmentBearings[i]
      }
    }
    return segmentBearings[segmentBearings.count - 1]
  }

  /// Calculates the great-circle initial forward azimuth (bearing) from one coordinate to another.
  public static func calculateBearing(
    from: LatLngAltitude,
    to: LatLngAltitude,
    fallbackBearing: Double = 0.0
  ) -> Double {
    let dist = FlightMath.greatCircleDistanceMeters(
      lat1: from.latitude,
      lon1: from.longitude,
      lat2: to.latitude,
      lon2: to.longitude
    )
    guard dist >= 1e-6 else {
      return fallbackBearing
    }

    return FlightMath.greatCircleBearingDegrees(
      lat1: from.latitude,
      lon1: from.longitude,
      lat2: to.latitude,
      lon2: to.longitude
    )
  }

  /// Computes the forward heading azimuth to a target point located `lookAheadDistance` meters ahead.
  ///
  /// Preserves the active segment's bearing if the look-ahead span has zero length (e.g., on duplicate
  /// points or at the end of the path).
  public func lookAheadHeading(at currentDistance: Double, lookAheadDistance: Double) -> Double {
    let clampedCurrent = max(0, min(currentDistance, totalLength))
    let clampedTarget = max(0, min(clampedCurrent + lookAheadDistance, totalLength))
    let fallback = segmentBearing(at: clampedCurrent)

    guard clampedTarget - clampedCurrent >= 1e-6 else {
      return fallback
    }

    let currentPos = position(at: clampedCurrent)
    let targetPos = position(at: clampedTarget)
    return Self.calculateBearing(from: currentPos, to: targetPos, fallbackBearing: fallback)
  }
}
