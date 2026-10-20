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
  private static let origin = LatLngAltitude(latitude: 51.5072178, longitude: -0.1275862)
  private static let destination = LatLngAltitude(latitude: 51.5007292, longitude: -0.1246254)

  // Cache static Marker3Ds outside body so they are not re-rasterized on camera changes
  @MainActor
  private static let originMarker = Marker3D(
    position: origin,
    altitudeMode: .clampToGround,
    label: "Origin"
  )

  @MainActor
  private static let destinationMarker = Marker3D(
    position: destination,
    altitudeMode: .clampToGround,
    label: "Destination"
  )

  @State private var routePath: [LatLngAltitude] = []
  @State private var camera: Camera = .init(
    center: .init(latitude: 51.5072, longitude: -0.1276, altitude: 0),
    range: 400
  )
  @State private var isShowingError: Bool = false
  @State private var errorMessage: String = ""
  @StateObject private var routeHelper = RouteHelper()

  var body: some View {
    VStack {
      Map(camera: $camera, mode: .roadmap) {
        if !routePath.isEmpty {
          Polyline(path: routePath, altitudeMode: .relativeToMesh)
            .stroke(
              .init(
                strokeColor: .systemBlue,
                strokeWidth: 12.0,
                outerColor: .white,
                outerWidth: 0.25
              )
            )
            .contour(
              .init(
                geodesic: true,
                extruded: false,
                drawOccludedSegments: true
              )
            )
        }
        Self.originMarker
        Self.destinationMarker
      }

      Button("Calculate Route") {
        // You need an API Key that has Routes API enabled.
        // Either:
        // 1. Enable Routes API on your existing Maps 3D API key, or
        // 2. Comment this line and edit RouteHelper.swift to add a Routes API key there.
        if routeHelper.routesApiKey.isEmpty {
          routeHelper.routesApiKey = Map.apiKey
        }
        Task {
          await routeRequest()
        }
      }
      .buttonStyle(.borderedProminent)
      .padding(.bottom, 8)
    }
    .navigationTitle("Routes API Demo")
    .navigationBarTitleDisplayMode(.inline)
    .alert("Routes API Error", isPresented: $isShowingError) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(errorMessage)
    }
  }

  @MainActor
  private func routeRequest() async {
    do {
      let route = try await routeHelper.fetchRoute(
        origin: Self.origin,
        destination: Self.destination
      )
      self.routePath = route
      if let newCamera = routeHelper.calculateCamera(for: route) {
        self.camera = newCamera
      }
    } catch {
      errorMessage = error.localizedDescription
      isShowingError = true
    }
  }
}
