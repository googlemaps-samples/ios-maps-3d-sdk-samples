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

struct OutdoorActivityDemo: View {
  // Yosemite Mountain Switchback Trail waypoints (42 coordinates)
  // Polyline altitudes set at 40m relative to the 3D surface mesh to clear the tree canopy.
  private static let yosemiteTrail: [LatLngAltitude] = [
    .init(latitude: 37.73290, longitude: -119.55770, altitude: 40.0),
    .init(latitude: 37.73278, longitude: -119.55748, altitude: 40.0),
    .init(latitude: 37.73265, longitude: -119.55725, altitude: 40.0),
    .init(latitude: 37.73251, longitude: -119.55701, altitude: 40.0),
    .init(latitude: 37.73238, longitude: -119.55678, altitude: 40.0),
    .init(latitude: 37.73224, longitude: -119.55655, altitude: 40.0),
    .init(latitude: 37.73210, longitude: -119.55632, altitude: 40.0),
    .init(latitude: 37.73200, longitude: -119.55605, altitude: 40.0),
    .init(latitude: 37.73212, longitude: -119.55580, altitude: 40.0),
    .init(latitude: 37.73225, longitude: -119.55556, altitude: 40.0),
    .init(latitude: 37.73239, longitude: -119.55532, altitude: 40.0),
    .init(latitude: 37.73252, longitude: -119.55508, altitude: 40.0),
    .init(latitude: 37.73266, longitude: -119.55485, altitude: 40.0),
    .init(latitude: 37.73258, longitude: -119.55458, altitude: 40.0),
    .init(latitude: 37.73247, longitude: -119.55432, altitude: 40.0),
    .init(latitude: 37.73235, longitude: -119.55408, altitude: 40.0),
    .init(latitude: 37.73222, longitude: -119.55385, altitude: 40.0),
    .init(latitude: 37.73210, longitude: -119.55360, altitude: 40.0),
    .init(latitude: 37.73198, longitude: -119.55335, altitude: 40.0),
    .init(latitude: 37.73208, longitude: -119.55308, altitude: 40.0),
    .init(latitude: 37.73220, longitude: -119.55282, altitude: 40.0),
    .init(latitude: 37.73231, longitude: -119.55258, altitude: 40.0),
    .init(latitude: 37.73243, longitude: -119.55232, altitude: 40.0),
    .init(latitude: 37.73254, longitude: -119.55208, altitude: 40.0),
    .init(latitude: 37.73265, longitude: -119.55182, altitude: 40.0),
    .init(latitude: 37.73256, longitude: -119.55155, altitude: 40.0),
    .init(latitude: 37.73244, longitude: -119.55130, altitude: 40.0),
    .init(latitude: 37.73231, longitude: -119.55106, altitude: 40.0),
    .init(latitude: 37.73218, longitude: -119.55082, altitude: 40.0),
    .init(latitude: 37.73205, longitude: -119.55058, altitude: 40.0),
    .init(latitude: 37.73215, longitude: -119.55030, altitude: 40.0),
    .init(latitude: 37.73226, longitude: -119.55005, altitude: 40.0),
    .init(latitude: 37.73236, longitude: -119.54980, altitude: 40.0),
    .init(latitude: 37.73246, longitude: -119.54955, altitude: 40.0),
    .init(latitude: 37.73255, longitude: -119.54930, altitude: 40.0),
    .init(latitude: 37.73264, longitude: -119.54905, altitude: 40.0),
    .init(latitude: 37.73272, longitude: -119.54878, altitude: 40.0),
    .init(latitude: 37.73279, longitude: -119.54850, altitude: 40.0),
    .init(latitude: 37.73285, longitude: -119.54822, altitude: 40.0),
    .init(latitude: 37.73290, longitude: -119.54795, altitude: 40.0),
    .init(latitude: 37.73294, longitude: -119.54768, altitude: 40.0),
    .init(latitude: 37.73296, longitude: -119.54740, altitude: 40.0)
  ]

  // Pre-computed path metadata for terrain navigation
  private let trailMetadata = PathMetadata(path: yosemiteTrail)

  // Overview camera framing the full switchback canyon route
  private static let overviewCamera = Camera(
    center: .init(
      latitude: 37.73241,
      longitude: -119.55187,
      altitude: 1690.0
    ),
    heading: 90.0,
    tilt: 16.0,
    roll: 0.0,
    range: 3422.0,
    altitudeMode: .absolute
  )

  // Active hike camera with closer range (2300m) and dynamic tilt (50°)
  private static let activeHikeCamera = Camera(
    center: .init(
      latitude: 37.73241,
      longitude: -119.55187,
      altitude: 1690.0
    ),
    heading: 90.0,
    tilt: 50.0,
    roll: 0.0,
    range: 2300.0,
    altitudeMode: .absolute
  )

  // User-configurable speed multiplier (1x to 100x walking speed)
  @State private var speedMultiplier: Double = 20.0
  @State private var isAnimating: Bool = false

  // Simulation state
  @State private var accumulatedDistance: Double = 0.0
  @State private var lastFrameDate: Date? = nil
  @State private var hikerPosition: LatLngAltitude = yosemiteTrail[0]

  // Camera state
  @State private var camera: Camera = overviewCamera

  // Base human walking pace in meters per second (approx 3.5 mph)
  private let baseSpeedMps: Double = 1.56

  var body: some View {
    VStack(spacing: 0) {
      ZStack(alignment: .topLeading) {
        TimelineView(.animation(paused: !isAnimating)) { context in
          Map(camera: $camera, mode: .hybrid) {
            // Trail polyline styled relative to 3D terrain mesh
            Polyline(path: Self.yosemiteTrail, altitudeMode: .relativeToMesh)
              .stroke(
                .init(
                  strokeColor: .systemOrange,
                  strokeWidth: 8.0,
                  outerColor: .white
                )
              )
              .contour(
                .init(
                  geodesic: true,
                  extruded: false,
                  drawOccludedSegments: true
                )
              )

            // Start Marker (Trailhead)
            if let start = Self.yosemiteTrail.first {
              Marker3D(
                position: start,
                altitudeMode: .relativeToMesh,
                label: "Start",
                style: .pin(.init(backgroundColor: .blue))
              )
            }

            // Destination Marker (Summit Crest)
            if let destination = Self.yosemiteTrail.last {
              Marker3D(
                position: destination,
                altitudeMode: .relativeToMesh,
                label: "Destination",
                style: .pin(.init(backgroundColor: .green))
              )
            }

            // Animated Hiker Marker progressing along the trail
            Marker3D(
              position: hikerPosition,
              altitudeMode: .relativeToMesh,
              extruded: true,
              label: "Hiker",
              style: .pin(.init(backgroundColor: .red))
            )
          }
          .onChange(of: context.date) { _, newDate in
            if isAnimating {
              updateSimulation(at: newDate)
            }
          }
        }

        // Live Real-Time Debug HUD Overlay
        VStack(alignment: .leading, spacing: 2) {
          Text("Hiker: \(hikerPosition.latitude, specifier: "%.5f"), \(hikerPosition.longitude, specifier: "%.5f")")
          Text("Cam Center: \(camera.center.latitude, specifier: "%.5f"), \(camera.center.longitude, specifier: "%.5f") (alt: \(camera.center.altitude, specifier: "%.0f")m)")
          Text("Cam Range: \(camera.range, specifier: "%.0f")m | Tilt: \(camera.tilt, specifier: "%.0f")° | Heading: \(camera.heading, specifier: "%.0f")°")
          Text("AltMode: \(String(describing: camera.altitudeMode)) | Progress: \(accumulatedDistance, specifier: "%.0f")m / \(trailMetadata.totalLength, specifier: "%.0f")m")
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
          Text("Speed: \(Int(speedMultiplier))x")
            .font(.caption.monospacedDigit().bold())
            .frame(width: 80, alignment: .leading)
          Slider(value: $speedMultiplier, in: 1.0...100.0, step: 1.0)
          Text("\(speedMultiplier * 3.5, specifier: "%.0f") mph")
            .font(.caption.monospacedDigit())
            .foregroundColor(.secondary)
            .frame(width: 50, alignment: .trailing)
        }

        HStack(spacing: 16) {
          Button(isAnimating ? "Pause" : "Start Hike") {
            isAnimating.toggle()
            if isAnimating {
              lastFrameDate = Date()
              camera = Self.activeHikeCamera
            }
          }
          .buttonStyle(.borderedProminent)

          Button("Reset") {
            resetSimulation()
          }
          .buttonStyle(.bordered)
        }
      }
      .padding(.horizontal)
      .padding(.vertical, 10)
      .background(.ultraThinMaterial)
    }
    .navigationTitle("Outdoor Activity")
    .onAppear {
      resetSimulation()
    }
  }

  private func resetSimulation() {
    isAnimating = false
    accumulatedDistance = 0.0
    lastFrameDate = nil

    hikerPosition = trailMetadata.position(at: 0)
    camera = Self.overviewCamera
  }

  private func updateSimulation(at currentDate: Date) {
    guard isAnimating else { return }

    let dt = currentDate.timeIntervalSince(lastFrameDate ?? currentDate)
    lastFrameDate = currentDate

    let effectiveSpeedMps = baseSpeedMps * speedMultiplier
    accumulatedDistance += dt * effectiveSpeedMps

    if accumulatedDistance >= trailMetadata.totalLength {
      accumulatedDistance = 0.0 // Loop continuously
    }

    // Update hiker position along the trail relative to the terrain mesh
    hikerPosition = trailMetadata.position(at: accumulatedDistance)
  }
}

#Preview {
  OutdoorActivityDemo()
}
