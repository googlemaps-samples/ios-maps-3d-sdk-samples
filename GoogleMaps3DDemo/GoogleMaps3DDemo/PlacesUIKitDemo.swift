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
import GoogleMaps3DKit
import SwiftUI

/// Demonstrates the embedded Places UI Kit capability provided by `GoogleMaps3DKit`.
///
/// In Maps 3D SDK v1.0.0, enabling `.placeInformationEnabled(true)` connects 3D map
/// POI interactions directly to the built-in Places UI Kit sheet without requiring
/// manual Places API queries or separate Places view components.
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

  @State private var placeInformationEnabled: Bool = true
  @State private var tapActionOption: TapActionOption = .defaultCard
  @State private var lastTappedPlaceID: String? = nil
  @State private var selectedLandmarkID: String = "ChIJWTGPjmaAhYARxz6l1hOj92w"

  enum TapActionOption: String, CaseIterable, Identifiable {
    case defaultCard = "Show Built-in Card"
    case none = "Suppress Card"

    var id: String { rawValue }

    var action: PlaceTapAction {
      switch self {
      case .defaultCard: return .default
      case .none: return .none
      }
    }
  }

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
    ),
    LandmarkItem(
      id: "ChIJ-2374-CAhYARg1V85E1b-b4",
      name: "Salesforce Tower",
      coordinate: .init(latitude: 37.7897, longitude: -122.3972, altitude: 0)
    )
  ]

  var body: some View {
    VStack(spacing: 0) {
      // 3D Map View with embedded GoogleMaps3DKit Places capability
      Map(camera: $camera, mode: .hybrid) {
        ForEach(landmarks) { landmark in
          Marker3D(
            position: landmark.coordinate,
            altitudeMode: .relativeToMesh,
            label: landmark.name
          )
        }
      }
      .placeInformationEnabled(placeInformationEnabled)
      .onPlaceTap { placeId in
        lastTappedPlaceID = placeId
        return tapActionOption.action
      }
      .flyCameraTo(
        targetCamera,
        duration: 2.5,
        trigger: flyTrigger
      )

      // Controls & Information Panel
      VStack(spacing: 10) {
        // Preset landmark quick navigation
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            ForEach(landmarks) { landmark in
              Button(landmark.name) {
                selectLandmark(landmark)
              }
              .buttonStyle(.bordered)
              .tint(selectedLandmarkID == landmark.id ? .blue : .secondary)
            }
          }
          .padding(.horizontal)
        }

        Divider()

        // Place Information toggles
        HStack {
          Toggle("Place Info Enabled", isOn: $placeInformationEnabled)
            .font(.subheadline)
        }
        .padding(.horizontal)

        // Action configuration
        HStack {
          Text("On Place Tap:")
            .font(.subheadline.bold())
          Picker("On Place Tap", selection: $tapActionOption) {
            ForEach(TapActionOption.allCases) { option in
              Text(option.rawValue).tag(option)
            }
          }
          .pickerStyle(.segmented)
        }
        .padding(.horizontal)

        // Live status & explanation
        VStack(alignment: .leading, spacing: 4) {
          if let placeId = lastTappedPlaceID {
            HStack {
              Image(systemName: "mappin.and.ellipse")
                .foregroundColor(.blue)
              Text("Tapped Place ID:")
                .font(.caption.bold())
              Text(placeId)
                .font(.caption.monospaced())
                .lineLimit(1)
                .truncationMode(.middle)
            }
          } else {
            HStack {
              Image(systemName: "hand.tap")
                .foregroundColor(.secondary)
              Text("Tap any 3D building or POI on the map to trigger place details.")
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }

          Text("GoogleMaps3DKit embeds the Places UI Kit details sheet directly. Returning .default displays the sheet; returning .none suppresses it.")
            .font(.caption2)
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.primary.opacity(0.05))
        .cornerRadius(8)
        .padding(.horizontal)
      }
      .padding(.vertical, 10)
      .background(.ultraThinMaterial)
    }
    .navigationTitle("Places UI Kit")
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      selectLandmark(landmarks[0])
    }
  }

  private func selectLandmark(_ landmark: LandmarkItem) {
    selectedLandmarkID = landmark.id
    lastTappedPlaceID = landmark.id
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
}

#Preview {
  PlacesUIKitDemo()
}
