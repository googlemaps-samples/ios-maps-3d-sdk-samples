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
import GoogleMaps3D
import SwiftUI

/// Supported camera perspectives for the flight simulation.
enum FlightCameraMode: String, CaseIterable, Identifiable {
  case chase = "Chase (Following)"
  case topDown = "Top-Down"

  var id: String { rawValue }
}

/// Data structure for smooth telemetry playback using Catmull-Rom cubic splines
/// to eliminate raw GPS jitter and deliver smooth continuous 3D flight.
struct FlightTimelineMetadata {
  let steps: [FlightPathLocation]
  let elapsedSeconds: [Double]
  let totalDuration: Double
  let points: [LatLngAltitude]

  init(flight: [FlightPathLocation]) {
    self.steps = flight
    self.points = flight.map {
      LatLngAltitude(latitude: $0.latitude, longitude: $0.longitude, altitude: $0.altitude)
    }

    guard let startTimestamp = flight.first?.timestamp else {
      self.elapsedSeconds = []
      self.totalDuration = 1.0
      return
    }

    var times: [Double] = []
    for step in flight {
      let t = Double(step.timestamp - startTimestamp) / 1000.0
      times.append(t)
    }
    self.elapsedSeconds = times
    self.totalDuration = max(times.last ?? 1.0, 1.0)
  }

  /// Evaluates Catmull-Rom cubic spline position at normalized parameter `u` between points p1 and p2.
  private func catmullRom(p0: Double, p1: Double, p2: Double, p3: Double, u: Double) -> Double {
    let u2 = u * u
    let u3 = u2 * u
    return 0.5 * (
      (2.0 * p1) +
      (-p0 + p2) * u +
      (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * u2 +
      (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * u3
    )
  }

  /// Evaluates smooth 3D position at a given elapsed time.
  func position(at time: Double) -> LatLngAltitude {
    guard steps.count > 1 else {
      return points.first ?? LatLngAltitude(latitude: 0, longitude: 0, altitude: 0)
    }

    let clampedTime = max(0, min(time, totalDuration))

    for i in 0..<(elapsedSeconds.count - 1) {
      let tStart = elapsedSeconds[i]
      let tEnd = elapsedSeconds[i + 1]

      if clampedTime >= tStart && clampedTime <= tEnd {
        let segDuration = tEnd - tStart
        let u = segDuration > 0 ? (clampedTime - tStart) / segDuration : 0.0

        let i0 = max(0, i - 1)
        let i1 = i
        let i2 = i + 1
        let i3 = min(steps.count - 1, i + 2)

        let s0 = steps[i0]
        let s1 = steps[i1]
        let s2 = steps[i2]
        let s3 = steps[i3]

        let lat = catmullRom(p0: s0.latitude, p1: s1.latitude, p2: s2.latitude, p3: s3.latitude, u: u)
        let lon = catmullRom(p0: s0.longitude, p1: s1.longitude, p2: s2.longitude, p3: s3.longitude, u: u)
        let alt = catmullRom(p0: s0.altitude, p1: s1.altitude, p2: s2.altitude, p3: s3.altitude, u: u)

        return LatLngAltitude(latitude: lat, longitude: lon, altitude: alt)
      }
    }

    let last = steps.last!
    return LatLngAltitude(latitude: last.latitude, longitude: last.longitude, altitude: last.altitude)
  }

  /// Samples continuous 3D position, smoothly eased airspeed, and look-ahead bearing.
  func sample(at time: Double, lookAheadSeconds: Double = 3.0) -> (position: LatLngAltitude, speedKnots: Double, bearing: Double) {
    let currentPos = position(at: time)
    let forwardPos = position(at: time + lookAheadSeconds)

    // Smooth forward bearing computed from continuous cubic trajectory
    let bearing = PathMetadata.calculateBearing(from: currentPos, to: forwardPos)

    // Smooth hermite airspeed easing
    var speed: Double = steps.first?.speed ?? 240.0
    let clampedTime = max(0, min(time, totalDuration))
    for i in 0..<(elapsedSeconds.count - 1) {
      let tStart = elapsedSeconds[i]
      let tEnd = elapsedSeconds[i + 1]
      if clampedTime >= tStart && clampedTime <= tEnd {
        let segDuration = tEnd - tStart
        let u = segDuration > 0 ? (clampedTime - tStart) / segDuration : 0.0
        // Smoothstep cubic easing: 3u^2 - 2u^3
        let smoothU = u * u * (3.0 - 2.0 * u)
        let v1 = steps[i].speed
        let v2 = steps[i + 1].speed
        speed = v1 + (v2 - v1) * smoothU
        break
      }
    }

    return (currentPos, speed, bearing)
  }
}

struct FlyAlongRouteDemo: View {
  @StateObject private var flightDataLoader = FlightDataLoader()

  // Initial flight origin (Austrian Alps descent into Innsbruck)
  private static let startPosition = LatLngAltitude(
    latitude: 47.3844,
    longitude: 11.8412,
    altitude: 2872.74
  )

  // Pre-computed flight timeline metadata
  @State private var flightTimeline: FlightTimelineMetadata? = nil

  // Cached 3D model asset URL to prevent per-frame Bundle lookups
  private static let airplaneModelUrl = Bundle.main.url(forResource: "Airplane", withExtension: "glb")

  // Telemetry playback & camera settings
  @State private var cameraMode: FlightCameraMode = .chase
  @State private var speedMultiplier: Double = 5.0
  @State private var isAnimating: Bool = false

  // Simulation state driven by recorded flight timeline
  @State private var elapsedTime: Double = 0.0
  @State private var lastFrameDate: Date? = nil
  @State private var planePosition: LatLngAltitude = startPosition
  @State private var planeHeading: Double = 237.0
  @State private var currentAirspeedKnots: Double = 240.0

  // 3D Airplane model scale
  private let planeScale: Double = 0.05

  // Camera state: chase camera starts 750m behind the aircraft at 75° tilt
  @State private var camera: Camera = .init(
    center: startPosition,
    heading: 237.0,
    tilt: 75.0,
    roll: 0.0,
    range: 750.0,
    altitudeMode: .absolute
  )

  var body: some View {
    VStack(spacing: 0) {
      ZStack(alignment: .topLeading) {
        TimelineView(.animation(paused: !isAnimating)) { context in
          Map(camera: $camera, mode: .hybrid) {
            // 3D Descent flight corridor polyline
            if let timeline = flightTimeline {
              Polyline(path: timeline.points, altitudeMode: .absolute)
                .stroke(
                  .init(
                    strokeColor: .cyan,
                    strokeWidth: 5.0,
                    outerColor: .white
                  )
                )
                .contour(
                  .init(
                    geodesic: true,
                    extruded: true,
                    drawOccludedSegments: true
                  )
                )
            }

            // 3D Airplane Model (wings level, white/blue livery, forward aligned)
            if let modelUrl = Self.airplaneModelUrl {
              Model(
                position: planePosition,
                url: modelUrl,
                altitudeMode: .absolute,
                scale: .init(x: planeScale, y: planeScale, z: planeScale),
                orientation: .init(
                  heading: planeHeading,
                  tilt: 0.0,
                  roll: 0.0
                )
              )
            }
          }
          .onChange(of: context.date) { _, newDate in
            if isAnimating {
              updateSimulation(at: newDate)
            }
          }
        }

        // Real-Time Flight Telemetry HUD displaying recorded speed and altitude
        VStack(alignment: .leading, spacing: 2) {
          Text("Aircraft: \(planePosition.latitude, specifier: "%.4f"), \(planePosition.longitude, specifier: "%.4f")")
          Text("Altitude: \(planePosition.altitude, specifier: "%.0f") m (\(planePosition.altitude * 3.28084, specifier: "%.0f") ft MSL)")
          Text("Airspeed: \(currentAirspeedKnots, specifier: "%.0f") kts (\(currentAirspeedKnots * 1.852, specifier: "%.0f") km/h)")
          Text("Heading: \(planeHeading, specifier: "%.0f")° | Cam: \(cameraMode.rawValue)")
          if let timeline = flightTimeline {
            Text("Recorded Time: \(formatTime(elapsedTime)) / \(formatTime(timeline.totalDuration)) (\(Int((elapsedTime / timeline.totalDuration) * 100))%)")
          }
        }
        .font(.system(size: 9, weight: .bold, design: .monospaced))
        .foregroundColor(.primary)
        .padding(6)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .padding(8)
      }

      // Simulation Controls Sheet
      VStack(spacing: 10) {
        // Camera View Mode Selector
        Picker("Camera Perspective", selection: $cameraMode) {
          ForEach(FlightCameraMode.allCases) { mode in
            Text(mode.rawValue).tag(mode)
          }
        }
        .pickerStyle(.segmented)
        .onChange(of: cameraMode) { _, newMode in
          applyCameraMode(newMode, position: planePosition, heading: planeHeading)
        }

        HStack {
          Text("Playback: \(speedMultiplier, specifier: "%.0f")x")
            .font(.caption.monospacedDigit().bold())
            .frame(width: 110, alignment: .leading)
          Slider(value: $speedMultiplier, in: 1...20, step: 1)
        }

        HStack(spacing: 20) {
          Button(isAnimating ? "Pause Flight" : "Replay Flight") {
            isAnimating.toggle()
            if isAnimating {
              lastFrameDate = Date()
            }
          }
          .buttonStyle(.borderedProminent)

          Button("Reset") {
            resetSimulation()
          }
          .buttonStyle(.bordered)
        }
      }
      .padding()
      .background(.ultraThinMaterial)
    }
    .navigationTitle("Flight Path")
    .onAppear {
      initializeFlightTimeline()
    }
  }

  private func initializeFlightTimeline() {
    let flight = flightDataLoader.flightPathData.flight
    guard !flight.isEmpty else { return }

    let timeline = FlightTimelineMetadata(flight: flight)
    self.flightTimeline = timeline
    resetSimulation()
  }

  private func resetSimulation() {
    isAnimating = false
    elapsedTime = 0.0
    lastFrameDate = nil

    guard let timeline = flightTimeline, let firstStep = flightDataLoader.flightPathData.flight.first else {
      return
    }

    let initialPos = timeline.points[0]
    let initialHeading = firstStep.bearing

    planePosition = initialPos
    planeHeading = initialHeading
    currentAirspeedKnots = firstStep.speed

    applyCameraMode(cameraMode, position: initialPos, heading: initialHeading)
  }

  private func updateSimulation(at currentDate: Date) {
    guard isAnimating, let timeline = flightTimeline else { return }

    let dt = currentDate.timeIntervalSince(lastFrameDate ?? currentDate)
    lastFrameDate = currentDate

    // Advance playback along the recorded flight timeline
    elapsedTime += dt * speedMultiplier

    if elapsedTime > timeline.totalDuration {
      elapsedTime = 0.0 // Loop replay continuously
    }

    // 1. Sample continuous Catmull-Rom cubic position, smoothly eased airspeed, and look-ahead bearing
    let sample = timeline.sample(at: elapsedTime, lookAheadSeconds: 3.0)

    planePosition = sample.position
    planeHeading = sample.bearing
    currentAirspeedKnots = sample.speedKnots

    // 2. Camera Chase / Top-Down follow
    applyCameraMode(cameraMode, position: sample.position, heading: sample.bearing)
  }

  private func applyCameraMode(_ mode: FlightCameraMode, position: LatLngAltitude, heading: Double) {
    switch mode {
    case .chase:
      camera = Camera(
        center: position,
        heading: heading,
        tilt: 75.0,
        roll: 0.0,
        range: 750.0,
        altitudeMode: .absolute
      )
    case .topDown:
      camera = Camera(
        center: position,
        heading: heading,
        tilt: 0.0,
        roll: 0.0,
        range: 1500.0,
        altitudeMode: .absolute
      )
    }
  }

  private func formatTime(_ seconds: Double) -> String {
    let totalSec = Int(seconds)
    let min = totalSec / 60
    let sec = totalSec % 60
    return String(format: "%02d:%02d", min, sec)
  }
}

#Preview {
  FlyAlongRouteDemo()
}
