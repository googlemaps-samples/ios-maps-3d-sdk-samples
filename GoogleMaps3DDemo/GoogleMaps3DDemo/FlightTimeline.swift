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
import SwiftUI

/// Snapshot of interpolated aircraft state along a recorded flight path.
struct FlightTimelineSample {
  let position: LatLngAltitude
  let speedKnots: Double
  let heading: Double
  let pitchDegrees: Double
  let rollDegrees: Double
  let currentSegmentIndex: Int
}

/// Pre-computed cubic keyframe descriptor for `KeyframeTimeline` / `KeyframeTrack` camera tracks.
struct CameraCubicKeyframeSpec {
  let camera: Camera
  let duration: TimeInterval
  let startVelocity: Camera
  let endVelocity: Camera
}

/// Constant-speed 3D flight timeline parameterized by cumulative arc-length distance.
///
/// Uses Fritsch-Carlson monotone cubic Hermite interpolation (`CubicKeyframe` compatible)
/// parameterized by 3D segment distance so the aircraft and camera glide smoothly through
/// every coordinate at constant speed with zero vertical overshoot ("bounce").
struct FlightTimeline {
  /// Constant base cruise speed in knots before the playback multiplier is applied.
  static let constantCruiseSpeedKnots: Double = 200.0

  let steps: [FlightPathLocation]
  let points: [LatLngAltitude]
  let cumulativeDistances: [Double]
  let segmentDistances: [Double]
  let totalDistance: Double

  /// Monotone spatial derivatives `(dLat/ds, dLon/ds, dAlt/ds, dBearing/ds)` at each waypoint knot.
  private let knotLatSlopes: [Double]
  private let knotLonSlopes: [Double]
  private let knotAltSlopes: [Double]
  private let unwrappedBearings: [Double]
  private let knotBearingSlopes: [Double]

  /// Pre-subdivided points per segment so the 3D renderer does not frustum-clip long 3km segments
  /// while the aircraft is still flying along them.
  private let subdividedSegments: [[LatLngAltitude]]

  /// Pre-built SwiftUI `KeyframeTimeline<Camera>` tracks (parameterized by distance in meters)
  /// using `CubicKeyframe<Camera>` so Keyframe mode supports pause, resume, and instant reset.
  private let chaseKeyframeTimeline: KeyframeTimeline<Camera>
  private let topDownKeyframeTimeline: KeyframeTimeline<Camera>

  /// Synchronously loads the bundled `flightpath.json` timeline so views have full route data on initial render.
  static func loadDefault() -> FlightTimeline {
    let loader = FlightDataLoader()
    return FlightTimeline(flight: loader.flightPathData.flight)
  }

  init(flight: [FlightPathLocation]) {
    self.steps = flight
    let rawPoints = flight.map {
      LatLngAltitude(latitude: $0.latitude, longitude: $0.longitude, altitude: $0.altitude)
    }
    self.points = rawPoints

    guard flight.count > 1 else {
      let fallbackPos = rawPoints.first ?? LatLngAltitude(latitude: 47.3844, longitude: 11.8412, altitude: 2872.74)
      let fallbackHeading = flight.first?.bearing ?? 237.0
      self.cumulativeDistances = [0.0]
      self.segmentDistances = []
      self.totalDistance = 1.0
      self.knotLatSlopes = [0.0]
      self.knotLonSlopes = [0.0]
      self.knotAltSlopes = [0.0]
      self.unwrappedBearings = [fallbackHeading]
      self.knotBearingSlopes = [0.0]
      self.subdividedSegments = rawPoints.isEmpty ? [] : [rawPoints]
      let chaseCam = FlightCameraRig.routeCamera(mode: .chase, position: fallbackPos, heading: fallbackHeading)
      let topCam = FlightCameraRig.routeCamera(mode: .topDown, position: fallbackPos, heading: fallbackHeading)
      self.chaseKeyframeTimeline = KeyframeTimeline(initialValue: chaseCam) {
        KeyframeTrack { CubicKeyframe(chaseCam, duration: 1.0) }
      }
      self.topDownKeyframeTimeline = KeyframeTimeline(initialValue: topCam) {
        KeyframeTrack { CubicKeyframe(topCam, duration: 1.0) }
      }
      return
    }

    var dists: [Double] = [0.0]
    var segDists: [Double] = []
    var runningDistance: Double = 0.0

    for i in 0..<(flight.count - 1) {
      let p1 = flight[i]
      let p2 = flight[i + 1]
      let horiz = FlightMath.greatCircleDistanceMeters(
        lat1: p1.latitude,
        lon1: p1.longitude,
        lat2: p2.latitude,
        lon2: p2.longitude
      )
      let dAlt = p2.altitude - p1.altitude
      let segDist = max(1.0, hypot(horiz, dAlt))
      segDists.append(segDist)
      runningDistance += segDist
      dists.append(runningDistance)
    }

    self.cumulativeDistances = dists
    self.segmentDistances = segDists
    self.totalDistance = max(runningDistance, 1.0)

    // Unwrap bearings so interpolations across 0°/360° are continuous
    var bearings: [Double] = [flight[0].bearing]
    for i in 1..<flight.count {
      let prev = bearings[i - 1]
      let delta = FlightMath.shortestAngleDelta(from: prev, to: flight[i].bearing)
      bearings.append(prev + delta)
    }
    self.unwrappedBearings = bearings

    // Compute Fritsch-Carlson monotone slopes with respect to arc-length distance
    let latValues = flight.map { $0.latitude }
    let lonValues = flight.map { $0.longitude }
    let altValues = flight.map { $0.altitude }

    let latSlopes = Self.computeMonotoneSlopes(values: latValues, segmentLengths: segDists)
    let lonSlopes = Self.computeMonotoneSlopes(values: lonValues, segmentLengths: segDists)
    let altSlopes = Self.computeMonotoneSlopes(values: altValues, segmentLengths: segDists)
    let bearingSlopes = Self.computeMonotoneSlopes(values: bearings, segmentLengths: segDists)

    self.knotLatSlopes = latSlopes
    self.knotLonSlopes = lonSlopes
    self.knotAltSlopes = altSlopes
    self.knotBearingSlopes = bearingSlopes

    // Subdivide each coordinate-to-coordinate segment along the monotone cubic curve (~50m intervals)
    var segments: [[LatLngAltitude]] = []
    for i in 0..<(flight.count - 1) {
      let segDist = segDists[i]
      let subdivisions = max(1, Int(ceil(segDist / 50.0)))
      var segPoints: [LatLngAltitude] = []
      for s in 0..<subdivisions {
        let u = Double(s) / Double(subdivisions)
        let lat = Self.evalHermite(
          p0: latValues[i], p1: latValues[i + 1],
          m0: latSlopes[i] * segDist, m1: latSlopes[i + 1] * segDist, u: u
        )
        let lon = Self.evalHermite(
          p0: lonValues[i], p1: lonValues[i + 1],
          m0: lonSlopes[i] * segDist, m1: lonSlopes[i + 1] * segDist, u: u
        )
        let alt = Self.evalHermite(
          p0: altValues[i], p1: altValues[i + 1],
          m0: altSlopes[i] * segDist, m1: altSlopes[i + 1] * segDist, u: u
        )
        segPoints.append(LatLngAltitude(latitude: lat, longitude: lon, altitude: alt))
      }
      if i == flight.count - 2 {
        let last = flight[flight.count - 1]
        segPoints.append(
          LatLngAltitude(latitude: last.latitude, longitude: last.longitude, altitude: last.altitude)
        )
      }
      segments.append(segPoints)
    }
    self.subdividedSegments = segments

    // Build distance-parameterized KeyframeTimeline<Camera> instances using CubicKeyframe<Camera>
    let chaseSpecs = Self.buildCubicSpecs(
      flight: flight,
      segDists: segDists,
      unwrappedBearings: bearings,
      latSlopes: latSlopes,
      lonSlopes: lonSlopes,
      altSlopes: altSlopes,
      bearingSlopes: bearingSlopes,
      mode: .chase
    )
    let topDownSpecs = Self.buildCubicSpecs(
      flight: flight,
      segDists: segDists,
      unwrappedBearings: bearings,
      latSlopes: latSlopes,
      lonSlopes: lonSlopes,
      altSlopes: altSlopes,
      bearingSlopes: bearingSlopes,
      mode: .topDown
    )

    let initialChase = FlightCameraRig.routeCamera(
      mode: .chase,
      position: rawPoints[0],
      heading: bearings[0]
    )
    let initialTopDown = FlightCameraRig.routeCamera(
      mode: .topDown,
      position: rawPoints[0],
      heading: bearings[0]
    )

    self.chaseKeyframeTimeline = KeyframeTimeline(initialValue: initialChase) {
      KeyframeTrack {
        for spec in chaseSpecs {
          CubicKeyframe(
            spec.camera,
            duration: spec.duration,
            startVelocity: spec.startVelocity,
            endVelocity: spec.endVelocity
          )
        }
      }
    }

    self.topDownKeyframeTimeline = KeyframeTimeline(initialValue: initialTopDown) {
      KeyframeTrack {
        for spec in topDownSpecs {
          CubicKeyframe(
            spec.camera,
            duration: spec.duration,
            startVelocity: spec.startVelocity,
            endVelocity: spec.endVelocity
          )
        }
      }
    }
  }

  private static func buildCubicSpecs(
    flight: [FlightPathLocation],
    segDists: [Double],
    unwrappedBearings: [Double],
    latSlopes: [Double],
    lonSlopes: [Double],
    altSlopes: [Double],
    bearingSlopes: [Double],
    mode: FlightCameraMode
  ) -> [CameraCubicKeyframeSpec] {
    var specs: [CameraCubicKeyframeSpec] = []
    specs.reserveCapacity(flight.count - 1)

    for i in 1..<flight.count {
      let segDist = segDists[i - 1]
      let targetStep = flight[i]
      let targetPos = LatLngAltitude(
        latitude: targetStep.latitude,
        longitude: targetStep.longitude,
        altitude: targetStep.altitude
      )
      let targetCam = FlightCameraRig.routeCamera(
        mode: mode,
        position: targetPos,
        heading: unwrappedBearings[i]
      )

      let startVel = Camera(
        center: LatLngAltitude(
          latitude: latSlopes[i - 1],
          longitude: lonSlopes[i - 1],
          altitude: altSlopes[i - 1]
        ),
        heading: bearingSlopes[i - 1],
        tilt: 0.0,
        roll: 0.0,
        range: 0.0
      )
      let endVel = Camera(
        center: LatLngAltitude(
          latitude: latSlopes[i],
          longitude: lonSlopes[i],
          altitude: altSlopes[i]
        ),
        heading: bearingSlopes[i],
        tilt: 0.0,
        roll: 0.0,
        range: 0.0
      )

      specs.append(
        CameraCubicKeyframeSpec(
          camera: targetCam,
          duration: segDist,
          startVelocity: startVel,
          endVelocity: endVel
        )
      )
    }

    return specs
  }

  /// Computes Fritsch-Carlson monotone cubic Hermite derivatives `dp/ds` at each knot.
  private static func computeMonotoneSlopes(
    values: [Double],
    segmentLengths: [Double]
  ) -> [Double] {
    let n = values.count
    guard n > 1, segmentLengths.count == n - 1 else {
      return Array(repeating: 0.0, count: n)
    }

    var secants: [Double] = []
    secants.reserveCapacity(n - 1)
    for i in 0..<(n - 1) {
      secants.append((values[i + 1] - values[i]) / max(1e-6, segmentLengths[i]))
    }

    var slopes = Array(repeating: 0.0, count: n)
    slopes[0] = secants[0]
    slopes[n - 1] = secants[n - 2]

    if n > 2 {
      for i in 1..<(n - 1) {
        let s0 = secants[i - 1]
        let s1 = secants[i]
        if s0 * s1 <= 0.0 {
          slopes[i] = 0.0
        } else {
          let h0 = segmentLengths[i - 1]
          let h1 = segmentLengths[i]
          // Brodlie weighted harmonic mean for unequal segment intervals, bounded to 3*min(|s0|, |s1|)
          let w1 = 2.0 * h1 + h0
          let w2 = h1 + 2.0 * h0
          let harmonic = (w1 + w2) / ((w1 / s0) + (w2 / s1))
          let limit = 3.0 * min(abs(s0), abs(s1))
          slopes[i] = harmonic < 0 ? max(harmonic, -limit) : min(harmonic, limit)
        }
      }
    }

    return slopes
  }

  /// Evaluates a cubic Hermite segment on `u in [0, 1]` given endpoint values `p0, p1` and scaled tangents `m0, m1`.
  private static func evalHermite(
    p0: Double,
    p1: Double,
    m0: Double,
    m1: Double,
    u: Double
  ) -> Double {
    let u2 = u * u
    let u3 = u2 * u
    let h00 = 2.0 * u3 - 3.0 * u2 + 1.0
    let h10 = u3 - 2.0 * u2 + u
    let h01 = -2.0 * u3 + 3.0 * u2
    let h11 = u3 - u2
    return h00 * p0 + h10 * m0 + h01 * p1 + h11 * m1
  }

  /// Returns the index of the coordinate-to-coordinate segment containing `distance`.
  func segmentIndex(atDistance distance: Double) -> Int {
    guard cumulativeDistances.count > 1 else { return 0 }
    let clampedDist = FlightMath.clamp(distance, min: 0.0, max: totalDistance)
    for i in 0..<(cumulativeDistances.count - 1) {
      if clampedDist >= cumulativeDistances[i] && clampedDist <= cumulativeDistances[i + 1] {
        return i
      }
    }
    return max(0, cumulativeDistances.count - 2)
  }

  /// Returns the polyline path keeping the full current coordinate-to-coordinate segment (and all
  /// upcoming segments), only trimming a segment after the plane has completely passed its end coordinate.
  func remainingPathPoints(forSegmentIndex activeSegmentIndex: Int) -> [LatLngAltitude] {
    guard !subdividedSegments.isEmpty else { return points }
    let safeIndex = max(0, min(activeSegmentIndex, subdividedSegments.count - 1))
    var result: [LatLngAltitude] = []
    for segIdx in safeIndex..<subdividedSegments.count {
      result.append(contentsOf: subdividedSegments[segIdx])
    }
    if result.count < 2, let last = points.last {
      result.append(last)
    }
    return result
  }

  /// Evaluates monotone cubic Hermite 3D position and heading at a given cumulative distance (in meters).
  func positionAndHeading(atDistance distance: Double) -> (position: LatLngAltitude, heading: Double) {
    guard steps.count > 1 else {
      let pos = points.first ?? LatLngAltitude(latitude: 0, longitude: 0, altitude: 0)
      return (pos, steps.first?.bearing ?? 237.0)
    }

    let clampedDist = FlightMath.clamp(distance, min: 0.0, max: totalDistance)

    for i in 0..<(cumulativeDistances.count - 1) {
      let dStart = cumulativeDistances[i]
      let dEnd = cumulativeDistances[i + 1]

      if clampedDist >= dStart && clampedDist <= dEnd {
        let segLength = max(1e-6, dEnd - dStart)
        let u = (clampedDist - dStart) / segLength

        let s1 = steps[i]
        let s2 = steps[i + 1]

        let lat = Self.evalHermite(
          p0: s1.latitude, p1: s2.latitude,
          m0: knotLatSlopes[i] * segLength, m1: knotLatSlopes[i + 1] * segLength, u: u
        )
        let lon = Self.evalHermite(
          p0: s1.longitude, p1: s2.longitude,
          m0: knotLonSlopes[i] * segLength, m1: knotLonSlopes[i + 1] * segLength, u: u
        )
        let alt = Self.evalHermite(
          p0: s1.altitude, p1: s2.altitude,
          m0: knotAltSlopes[i] * segLength, m1: knotAltSlopes[i + 1] * segLength, u: u
        )
        let rawBearing = Self.evalHermite(
          p0: unwrappedBearings[i], p1: unwrappedBearings[i + 1],
          m0: knotBearingSlopes[i] * segLength, m1: knotBearingSlopes[i + 1] * segLength, u: u
        )

        return (
          LatLngAltitude(latitude: lat, longitude: lon, altitude: alt),
          FlightMath.normalizeHeading(rawBearing)
        )
      }
    }

    let last = steps[steps.count - 1]
    return (
      LatLngAltitude(latitude: last.latitude, longitude: last.longitude, altitude: last.altitude),
      FlightMath.normalizeHeading(last.bearing)
    )
  }

  /// Samples 3D position and forward heading at `distance`.
  func sample(
    atDistance distance: Double,
    lookAheadMeters: Double = 150.0,
    previousHeading: Double? = nil,
    dt: Double = 1.0 / 60.0
  ) -> FlightTimelineSample {
    let clampedDist = FlightMath.clamp(distance, min: 0.0, max: totalDistance)
    let (currentPos, splineHeading) = positionAndHeading(atDistance: clampedDist)
    let currentSeg = segmentIndex(atDistance: clampedDist)

    let pitchDegrees = FlightMath.clamp(
      FlightMath.radiansToDegrees(atan(knotAltSlopes[currentSeg])),
      min: -25.0,
      max: 25.0
    )

    return FlightTimelineSample(
      position: currentPos,
      speedKnots: Self.constantCruiseSpeedKnots,
      heading: splineHeading,
      pitchDegrees: pitchDegrees,
      rollDegrees: 0.0,
      currentSegmentIndex: currentSeg
    )
  }

  /// Evaluates the pre-built SwiftUI `KeyframeTimeline<Camera>` (`CubicKeyframe<Camera>`) at `distance`.
  func sampleKeyframeCamera(
    atDistance distance: Double,
    mode: FlightCameraMode
  ) -> (camera: Camera, currentSegmentIndex: Int) {
    let clampedDist = FlightMath.clamp(distance, min: 0.0, max: totalDistance)
    let timeline = (mode == .chase) ? chaseKeyframeTimeline : topDownKeyframeTimeline
    var evaluatedCamera = timeline.value(time: clampedDist)
    // Sanitize fieldOfView so Camera.scale(by:)'s didSet [5°, 80°] clamp in GoogleMaps3D
    // does not oscillate FOV between 45° and 50° across keyframe segments.
    evaluatedCamera.fieldOfView = .degrees(35.0)
    evaluatedCamera.heading = FlightMath.normalizeHeading(evaluatedCamera.heading)
    let currentSeg = segmentIndex(atDistance: clampedDist)
    return (evaluatedCamera, currentSeg)
  }
}
