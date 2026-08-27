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
  public let totalLength: Double

  /// Initializes path metadata by pre-computing cumulative geodesic distances across all waypoints.
  public init(path: [LatLngAltitude]) {
    self.points = path
    var dists: [Double] = [0.0]
    var total: Double = 0.0

    if path.count > 1 {
      for i in 0..<(path.count - 1) {
        let p1 = CLLocation(latitude: path[i].latitude, longitude: path[i].longitude)
        let p2 = CLLocation(latitude: path[i + 1].latitude, longitude: path[i + 1].longitude)
        total += p1.distance(from: p2)
        dists.append(total)
      }
    }

    self.distances = dists
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
        let t = segmentDist > 0 ? (clampedDist - dStart) / segmentDist : 0.0
        let p1 = points[i]
        let p2 = points[i + 1]

        let lat = p1.latitude + (p2.latitude - p1.latitude) * t
        let lon = p1.longitude + (p2.longitude - p1.longitude) * t
        let alt = p1.altitude + (p2.altitude - p1.altitude) * t + altitudeOffset

        return LatLngAltitude(latitude: lat, longitude: lon, altitude: alt)
      }
    }

    let last = points.last!
    return LatLngAltitude(latitude: last.latitude, longitude: last.longitude, altitude: last.altitude + altitudeOffset)
  }

  /// Calculates the great-circle initial forward azimuth (bearing) from one coordinate to another.
  public static func calculateBearing(from: LatLngAltitude, to: LatLngAltitude) -> Double {
    let lat1 = from.latitude * .pi / 180
    let lon1 = from.longitude * .pi / 180
    let lat2 = to.latitude * .pi / 180
    let lon2 = to.longitude * .pi / 180

    let dLon = lon2 - lon1
    let y = sin(dLon) * cos(lat2)
    let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
    let radians = atan2(y, x)
    return (radians * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
  }

  /// Computes the forward heading azimuth to a target point located `lookAheadDistance` meters ahead.
  /// This provides smooth corner anticipation and eliminates abrupt frame-by-frame camera snapping.
  public func lookAheadHeading(at currentDistance: Double, lookAheadDistance: Double) -> Double {
    let currentPos = position(at: currentDistance)
    let targetPos = position(at: currentDistance + lookAheadDistance)
    return PathMetadata.calculateBearing(from: currentPos, to: targetPos)
  }
}
