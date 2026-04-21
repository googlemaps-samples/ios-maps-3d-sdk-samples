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

struct RoutesAPIDemo: View {
  @State private var routePath: [LatLngAltitude] = []
  @State private var camera: Camera = .init(
    center: .init(latitude: 51.5072, longitude: -0.1276, altitude: 0),
    range: 400
  )
  @State private var origin = LatLngAltitude(latitude: 51.5072178, longitude: -0.1275862)
  @State private var destination = LatLngAltitude(latitude: 51.5007292, longitude: -0.1246254)
  @StateObject private var routeHelper: RouteHelper = RouteHelper()

  var body: some View {
    VStack {
      Map(camera: $camera, mode: .roadmap) {
        if !routePath.isEmpty {
          Polyline(path: routePath, altitudeMode: .relativeToMesh)
            .stroke(.init(strokeColor: .systemBlue, strokeWidth: 12.0, outerColor: .systemBlue))
            .contour(.init(geodesic: true, extruded: true, drawOccludedSegments: true))
        }
        Marker3D(position: origin, altitudeMode: .clampToGround, label: "Origin")
        Marker3D(position: destination, altitudeMode: .clampToGround, label: "Destination")
      }
    }
    Button("Calculate Route") {
      // You need an API Key that has Routes API enabled.
      // Either
      // 1. Enable Routes API on your existing Maps 3D API key
      // Or
      // 2. Comment this line and edit RouteHelper.swift to add a Routes API key there.
      routeHelper.routesApiKey = Map.apiKey
      Task {
        await routeRequest()
      }
    }
  }

  private func routeRequest() async {
    do {
      let route = try await routeHelper.fetchRoute(origin: origin, destination: destination)

      // Calculate camera to fit the route
      if let newCamera = routeHelper.calculateCamera(for: route) {

        await MainActor.run {
          self.camera = newCamera
          self.routePath = route
        }
      }
    } catch {
      print("Error during route request: \(error)")
    }
  }
}
