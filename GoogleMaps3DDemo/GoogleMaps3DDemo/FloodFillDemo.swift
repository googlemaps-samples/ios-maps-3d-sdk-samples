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

import GoogleMaps3D
import SwiftUI

struct FloodFillDemo: View {
  private static let initialCamera = Camera(
    center: .dryFalls,
    heading: 45,
    tilt: 45,
    roll: 0,
    range: 1500,
    fieldOfView: .degrees(75)
  )

  private static let baseElevationMeters: Double = LatLngAltitude.dryFalls.altitude
  private static let maxElevationMeters: Double = 600.0

  @State private var currentAltitude: Double = LatLngAltitude.dryFalls.altitude

  private var floodPolygon: Polygon {
    let path = calculatePolygon(center: .dryFalls, altitude: currentAltitude)

    // Use .absolute altitudeMode so all vertices form a level water plane at a uniform MSL elevation
    return Polygon(path: path, altitudeMode: .absolute)
      .style(
        GoogleMaps3D.Polygon.StyleOptions(
          fillColor: .init(red: 0.0, green: 0.5, blue: 1.0, alpha: 0.75),
          extruded: true
        )
      )
  }

  var body: some View {
    VStack {
      Map(initialCamera: Self.initialCamera, mode: .hybrid) {
        floodPolygon
      }

      VStack(spacing: 16) {
        Text("Flood Water Elevation: \(Int(currentAltitude))m MSL")
          .font(.headline)

        Slider(
          value: $currentAltitude,
          in: Self.baseElevationMeters...Self.maxElevationMeters
        ) {
          Text("Altitude")
        } minimumValueLabel: {
          Text("\(Int(Self.baseElevationMeters))m")
        } maximumValueLabel: {
          Text("\(Int(Self.maxElevationMeters))m")
        }
        .padding(.horizontal)

        Text(
          "Base: \(Int(Self.baseElevationMeters))m MSL | Rise: +\(Int(currentAltitude - Self.baseElevationMeters))m"
        )
        .font(.subheadline)
        .foregroundColor(.secondary)
      }
      .padding()
      .background(.ultraThinMaterial)
    }
    .navigationTitle("Flood Fill Demo")
    .navigationBarTitleDisplayMode(.inline)
  }

  private func calculatePolygon(center: LatLngAltitude, altitude: Double) -> [LatLngAltitude] {
    let delta = 0.05
    return [
      .init(latitude: center.latitude + delta, longitude: center.longitude - delta, altitude: altitude),
      .init(latitude: center.latitude + delta, longitude: center.longitude + delta, altitude: altitude),
      .init(latitude: center.latitude - delta, longitude: center.longitude + delta, altitude: altitude),
      .init(latitude: center.latitude - delta, longitude: center.longitude - delta, altitude: altitude),
      .init(latitude: center.latitude + delta, longitude: center.longitude - delta, altitude: altitude),
    ]
  }
}

#Preview {
  FloodFillDemo()
}
