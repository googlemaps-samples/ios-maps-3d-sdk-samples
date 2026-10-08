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
import GoogleMaps3DKit
import GooglePlacesSwift
import SwiftUI

struct PlacesUIKitDemo: View {
  @State private var camera: Camera = .init(
    center: .init(latitude: 37.7955, longitude: -122.3937, altitude: 80),
    heading: 270,
    tilt: 60,
    roll: 0,
    range: 400
  )
  @State private var targetCamera: Camera = .init(
    center: .init(latitude: 37.7955, longitude: -122.3937, altitude: 80),
    heading: 270,
    tilt: 60,
    roll: 0,
    range: 400
  )
  @State private var flyTrigger: Bool = false

  @State private var isCompact: Bool = true
  @State private var selectedPlaceID: String = "ChIJWTGPjmaAhYARxz6l1hOj92w" // Ferry Building SF
  @State private var query: PlaceDetailsQuery = PlaceDetailsQuery(
    identifier: .placeID("ChIJWTGPjmaAhYARxz6l1hOj92w")
  )
  @State private var selectedLocation: LatLngAltitude? = .init(
    latitude: 37.7955,
    longitude: -122.3937,
    altitude: 0
  )
  @State private var selectedPlaceName: String = "Ferry Building"

  // Places UI Kit Configurations
  private let compactConfig = PlaceDetailsCompactConfiguration(
    content: [.address(), .rating(), .type()],
    theme: PlacesMaterialTheme()
  )

  private let fullConfig = PlaceDetailsConfiguration(
    content: [.address(), .rating(), .reviews(), .summary(), .media(), .type()],
    theme: PlacesMaterialTheme()
  )

  // Landmark Presets
  private struct LandmarkItem: Identifiable {
    let id: String // Place ID
    let name: String
    let coordinate: LatLngAltitude
  }

  private let landmarks: [LandmarkItem] = [
    LandmarkItem(
      id: "ChIJWTGPjmaAhYARxz6l1hOj92w",
      name: "Ferry Building",
      coordinate: .init(latitude: 37.7955, longitude: -122.3937, altitude: 0)
    ),
    LandmarkItem(
      id: "ChIJAQAAQIyAhYARRN3yIQG4hd4",
      name: "Coit Tower",
      coordinate: .init(latitude: 37.8024, longitude: -122.4058, altitude: 0)
    ),
    LandmarkItem(
      id: "ChIJgUYUENWGhYAR9awaWIrbYOk",
      name: "Palace of Fine Arts",
      coordinate: .init(latitude: 37.8029, longitude: -122.4484, altitude: 0)
    )
  ]

  var body: some View {
    VStack(spacing: 0) {
      // 3D Map View
      Map(camera: $camera, mode: .hybrid) {
        // Preset landmark pins
        ForEach(landmarks) { landmark in
          Marker3D(
            position: landmark.coordinate,
            altitudeMode: .relativeToMesh,
            label: landmark.name
          )
        }

        // Active selected marker pin
        if let location = selectedLocation {
          Marker3D(
            position: location,
            altitudeMode: .relativeToMesh,
            extruded: true,
            label: selectedPlaceName
          )
        }
      }
      .placeInformationEnabled(true)
      .onPlaceTap { placeId in
        selectPlace(placeID: placeId)
        return .default
      }
      .flyCameraTo(
        targetCamera,
        duration: 3,
        trigger: flyTrigger
      )
      .onTap { tapInfo in
        switch tapInfo.content {
        case .place(let placeId):
          selectPlace(placeID: placeId)
        default:
          break
        }
      }

      // Places UI Kit Control & Display Sheet
      if isPlacesApiKeyConfigured {
        VStack(spacing: 8) {
          // Landmark Quick-Selection Chips
          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
              ForEach(landmarks) { landmark in
                Button(landmark.name) {
                  selectLandmark(landmark)
                }
                .buttonStyle(.bordered)
                .tint(selectedPlaceID == landmark.id ? .blue : .secondary)
              }
            }
            .padding(.horizontal)
          }

          // Configuration Switcher (Compact vs Full)
          Picker("View Style", selection: $isCompact) {
            Text("Compact View").tag(true)
            Text("Full Details").tag(false)
          }
          .pickerStyle(.segmented)
          .padding(.horizontal)

          // Places UI Kit Details Component
          if isCompact {
            PlaceDetailsCompactView(
              orientation: .horizontal,
              query: $query,
              configuration: compactConfig,
              placeDetailsCallback: handlePlaceDetailsResult
            )
            .frame(height: 100)
            .padding(.horizontal)
          } else {
            PlaceDetailsView(
              orientation: .vertical,
              query: $query,
              configuration: fullConfig,
              placeDetailsCallback: handlePlaceDetailsResult
            )
            .frame(maxHeight: 320)
            .padding(.horizontal)
          }
        }
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
      } else {
        VStack(spacing: 10) {
          HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
              .foregroundColor(.orange)
            Text("Places API Key Required")
              .font(.subheadline.bold())
          }
          Text("To enable Places UI Kit components, add PLACES_API_KEY = your_key to Config.xcconfig")
            .font(.caption)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
      }
    }
    .navigationTitle("Places UI Kit")
    .onAppear {
      selectLandmark(landmarks[0])
    }
  }

  private var isPlacesApiKeyConfigured: Bool {
    guard let key = Bundle.main.infoDictionary?["PLACES_API_KEY"] as? String else {
      return false
    }
    return !key.isEmpty && key != "your_api_key_here" && !key.hasPrefix("$(")
  }

  private func selectLandmark(_ landmark: LandmarkItem) {
    selectedPlaceID = landmark.id
    selectedPlaceName = landmark.name
    selectedLocation = landmark.coordinate
    query = PlaceDetailsQuery(identifier: .placeID(landmark.id))
    targetCamera = Camera(
      center: .init(
        latitude: landmark.coordinate.latitude,
        longitude: landmark.coordinate.longitude,
        altitude: 80
      ),
      heading: 270,
      tilt: 60,
      roll: 0,
      range: 400
    )
    flyTrigger.toggle()
  }

  private func selectPlace(placeID: String) {
    selectedPlaceID = placeID
    query = PlaceDetailsQuery(identifier: .placeID(placeID))
  }

  private func handlePlaceDetailsResult(_ result: PlaceDetailsResult) {
    guard let place = result.place else {
      if let error = result.error {
        print("Place Details Error: \(error.localizedDescription)")
      }
      return
    }

    print("Place Details Result: \(String(describing: place))")

    // Update location and camera from Place location if available
    let location = place.location
    let newLocation = LatLngAltitude(
      latitude: location.latitude,
      longitude: location.longitude,
      altitude: 0
    )
    selectedLocation = newLocation

    targetCamera = Camera(
      center: .init(
        latitude: location.latitude,
        longitude: location.longitude,
        altitude: 80
      ),
      heading: camera.heading,
      tilt: 60,
      roll: 0,
      range: 400
    )
    flyTrigger.toggle()
  }
}

#Preview {
  PlacesUIKitDemo()
}
