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
  @State private var camera: Camera = .init(
    center: .dryFalls,
    heading: 45,
    tilt: 45,
    roll: 0,
    range: 500,
    fieldOfView: .init(degrees: 100),
    altitudeMode: .relativeToGround,
  )
  @State private var currentAltitude: Double = 0.0
  @State private var initialAltitude: Double = 0.0

  //@State private var polygonPoints: [LatLngAltitude] = []

  var floodPolygon: Polygon {

    let polygonPoints: [LatLngAltitude] = calculatePolygon(center: camera.center)

    let path = polygonPoints.map { latlng in
      LatLngAltitude(latitude: latlng.latitude, longitude: latlng.longitude, altitude: currentAltitude)
    }

    return Polygon(path: path, altitudeMode: .relativeToGround)
      .style(
        GoogleMaps3D.Polygon.StyleOptions(
          fillColor: .init(red: 0.0, green: 0.5, blue: 1.0, alpha: 0.75),
          extruded: true
        )
      )
  }

  var body: some View {
    VStack {
      Map(camera: $camera, mode: .hybrid) {
        floodPolygon
      }

      VStack(spacing: 20) {
        Text("Flood level: \(Int(currentAltitude))m")
          .font(.headline)

        Slider(value: $currentAltitude, in: (0...500)) {
          Text("Altitude")
        } minimumValueLabel: {
          Text("0")
        } maximumValueLabel: {
          Text("500")
        }
        .padding(.horizontal)
        Text("Initial: \(Int(initialAltitude))m, Current: \(Int(currentAltitude))m")
          .font(.headline)
      }
      .padding()
      .background(.ultraThinMaterial)
    }
    .onAppear {
        initialAltitude = camera.center.altitude
        currentAltitude = initialAltitude
      }
  }


  private func calculatePolygon(center: LatLngAltitude) -> [LatLngAltitude] {
    let altitude = center.altitude + 50
    // +/- 0.5 degress = 90-110km approx depending on latitude
    return [
      .init(latitude: center.latitude + 0.5, longitude: center.longitude - 0.5, altitude: altitude),
      .init(latitude: center.latitude + 0.5, longitude: center.longitude + 0.5, altitude: altitude),
      .init(latitude: center.latitude - 0.5, longitude: center.longitude + 0.5, altitude: altitude),
      .init(latitude: center.latitude - 0.5, longitude: center.longitude - 0.5, altitude: altitude),
      .init(latitude: center.latitude + 0.5, longitude: center.longitude - 0.5, altitude: altitude),
    ]
  }
}

