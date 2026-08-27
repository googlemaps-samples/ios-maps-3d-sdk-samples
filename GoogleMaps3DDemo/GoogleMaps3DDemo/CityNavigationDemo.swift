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

struct CityNavigationDemo: View {
  // San Francisco downtown street waypoints (30 coordinates)
  // Configured with 2.0m altitude relative to mesh to elevate the extruded polyline above asphalt seams.
  private static let coordinates: [LatLngAltitude] = [
    .init(latitude: 37.79446, longitude: -122.39479, altitude: 2.0),
    .init(latitude: 37.79442, longitude: -122.39469, altitude: 2.0),
    .init(latitude: 37.79323, longitude: -122.39322, altitude: 2.0),
    .init(latitude: 37.79166, longitude: -122.39519, altitude: 2.0),
    .init(latitude: 37.79124, longitude: -122.39571, altitude: 2.0),
    .init(latitude: 37.79105, longitude: -122.39599, altitude: 2.0),
    .init(latitude: 37.78893, longitude: -122.39866, altitude: 2.0),
    .init(latitude: 37.78742, longitude: -122.40060, altitude: 2.0),
    .init(latitude: 37.78686, longitude: -122.40129, altitude: 2.0),
    .init(latitude: 37.78652, longitude: -122.40171, altitude: 2.0),
    .init(latitude: 37.78632, longitude: -122.40196, altitude: 2.0),
    .init(latitude: 37.78627, longitude: -122.40207, altitude: 2.0),
    .init(latitude: 37.78453, longitude: -122.40429, altitude: 2.0),
    .init(latitude: 37.78443, longitude: -122.40434, altitude: 2.0),
    .init(latitude: 37.78155, longitude: -122.40802, altitude: 2.0),
    .init(latitude: 37.78005, longitude: -122.40990, altitude: 2.0),
    .init(latitude: 37.77856, longitude: -122.41180, altitude: 2.0),
    .init(latitude: 37.77746, longitude: -122.41318, altitude: 2.0),
    .init(latitude: 37.77624, longitude: -122.41474, altitude: 2.0),
    .init(latitude: 37.77744, longitude: -122.41623, altitude: 2.0),
    .init(latitude: 37.77749, longitude: -122.41636, altitude: 2.0),
    .init(latitude: 37.77761, longitude: -122.41654, altitude: 2.0),
    .init(latitude: 37.77769, longitude: -122.41677, altitude: 2.0),
    .init(latitude: 37.77729, longitude: -122.41981, altitude: 2.0),
    .init(latitude: 37.77523, longitude: -122.41938, altitude: 2.0),
    .init(latitude: 37.77510, longitude: -122.41934, altitude: 2.0),
    .init(latitude: 37.77442, longitude: -122.42022, altitude: 2.0),
    .init(latitude: 37.77441, longitude: -122.42033, altitude: 2.0),
    .init(latitude: 37.77348, longitude: -122.42157, altitude: 2.0),
    .init(latitude: 37.77244, longitude: -122.42289, altitude: 2.0)
  ]

  // Pre-computed path metadata for constant-speed navigation
  private let pathMetadata = PathMetadata(path: coordinates)

  // Cached model URL to prevent per-frame Bundle lookups and memory churn
  private static let carModelUrl = Bundle.main.url(forResource: "Car", withExtension: "glb")

  // User-configurable motion settings
  @State private var speedMph: Double = 30.0
  @State private var cameraLookAheadMeters: Double = 60.0
  @State private var isAnimating: Bool = false

  // 3D Model scaling (baked Z-up geometry enables pure tilt: 0, roll: 0 yaw rotation without gimbal lock)
  private let modelScale: Double = 0.075

  // Simulation state
  @State private var accumulatedDistance: Double = 0.0
  @State private var lastFrameDate: Date? = nil
  @State private var carPosition: LatLngAltitude = coordinates[0]
  @State private var carHeading: Double = 135.0

  // Initial street-corridor camera (range 130m, tilt 58°) positioned on Steuart St to avoid skyscraper occlusion
  @State private var camera: Camera = .init(
    center: .init(
      latitude: coordinates[0].latitude,
      longitude: coordinates[0].longitude,
      altitude: 15.0
    ),
    heading: 135.0,
    tilt: 58.0,
    roll: 0.0,
    range: 130.0,
    altitudeMode: .relativeToMesh
  )

  var body: some View {
    VStack(spacing: 0) {
      ZStack(alignment: .topLeading) {
        TimelineView(.animation(paused: !isAnimating)) { context in
          Map(camera: $camera, mode: .hybrid) {
            // Polyline styled like Google Maps navigation ribbon (wide stroke, outer border, 2m extruded elevation)
            Polyline(path: pathMetadata.points, altitudeMode: .relativeToMesh)
              .stroke(
                .init(
                  strokeColor: .systemBlue,
                  strokeWidth: 14.0,
                  outerColor: .white
                )
              )
              .contour(
                .init(
                  geodesic: false,
                  extruded: true,
                  drawOccludedSegments: true
                )
              )

            // 3D Car Model following the road with pure vertical yaw rotation (tilt: 0, roll: 0)
            if let modelUrl = Self.carModelUrl {
              Model(
                position: carPosition,
                url: modelUrl,
                altitudeMode: .relativeToMesh,
                scale: .init(x: modelScale, y: modelScale, z: modelScale),
                orientation: .init(
                  heading: carHeading,
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

        // Live Real-Time Debug HUD Overlay
        VStack(alignment: .leading, spacing: 2) {
          Text("Model: \(carPosition.latitude, specifier: "%.5f"), \(carPosition.longitude, specifier: "%.5f")")
          Text("Cam Center: \(camera.center.latitude, specifier: "%.5f"), \(camera.center.longitude, specifier: "%.5f") (alt: \(camera.center.altitude, specifier: "%.0f")m)")
          Text("Cam Range: \(camera.range, specifier: "%.0f")m | Tilt: \(camera.tilt, specifier: "%.0f")° | Heading: \(camera.heading, specifier: "%.0f")°")
          Text("Car Heading: \(carHeading, specifier: "%.0f")° | Progress: \(accumulatedDistance, specifier: "%.0f")m / \(pathMetadata.totalLength, specifier: "%.0f")m")
        }
        .font(.system(size: 9, weight: .bold, design: .monospaced))
        .foregroundColor(.primary)
        .padding(6)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .padding(8)
      }

      // Controls Sheet
      VStack(spacing: 10) {
        HStack {
          Text("Speed: \(speedMph, specifier: "%.0f") mph")
            .font(.caption.monospacedDigit().bold())
            .frame(width: 110, alignment: .leading)
          Slider(value: $speedMph, in: 10...60, step: 5)
        }

        HStack {
          Text("Look Ahead: \(cameraLookAheadMeters, specifier: "%.0f") m")
            .font(.caption.monospacedDigit().bold())
            .frame(width: 110, alignment: .leading)
          Slider(value: $cameraLookAheadMeters, in: 10...150, step: 10)
        }

        HStack(spacing: 20) {
          Button(isAnimating ? "Pause" : "Start Driving") {
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
    .navigationTitle("City Navigation")
    .onAppear {
      resetSimulation()
    }
  }

  private func resetSimulation() {
    isAnimating = false
    accumulatedDistance = 0.0
    lastFrameDate = nil

    let pos = pathMetadata.position(at: 0, altitudeOffset: 1.0)
    let initialCarHeading = pathMetadata.lookAheadHeading(at: 0, lookAheadDistance: 5.0)
    let initialCamHeading = pathMetadata.lookAheadHeading(at: 0, lookAheadDistance: cameraLookAheadMeters)

    carPosition = pos
    carHeading = initialCarHeading

    // Street-level camera (range 130m, tilt 58°) on Steuart St to avoid skyscraper occlusion
    camera = Camera(
      center: .init(latitude: pos.latitude, longitude: pos.longitude, altitude: 15.0),
      heading: initialCamHeading,
      tilt: 58.0,
      roll: 0.0,
      range: 130.0,
      altitudeMode: .relativeToMesh
    )
  }

  private func updateSimulation(at currentDate: Date) {
    guard isAnimating else { return }

    // Delta time step avoids teleporting when speed is adjusted dynamically
    let dt = currentDate.timeIntervalSince(lastFrameDate ?? currentDate)
    lastFrameDate = currentDate

    let speedMps = speedMph * 0.44704
    accumulatedDistance += dt * speedMps

    if accumulatedDistance > pathMetadata.totalLength {
      accumulatedDistance = 0.0 // Loop continuously
    }

    // 1. Get exact position along path at constant velocity
    let currentPos = pathMetadata.position(at: accumulatedDistance, altitudeOffset: 1.0)

    // 2. Car model only turns when within 5 meters of a corner (prevents pre-turn lane drifting)
    let modelTurnHeading = pathMetadata.lookAheadHeading(at: accumulatedDistance, lookAheadDistance: 5.0)

    // 3. Camera smoothly anticipates turns with the configurable look-ahead window (60m)
    let camFollowHeading = pathMetadata.lookAheadHeading(at: accumulatedDistance, lookAheadDistance: cameraLookAheadMeters)

    carPosition = currentPos
    carHeading = modelTurnHeading

    // 4. Smooth Camera Follow
    camera = Camera(
      center: .init(latitude: currentPos.latitude, longitude: currentPos.longitude, altitude: 15.0),
      heading: camFollowHeading,
      tilt: 58.0,
      roll: 0.0,
      range: 130.0,
      altitudeMode: .relativeToMesh
    )
  }
}

#Preview {
  CityNavigationDemo()
}
