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

struct MapTapDemo: View {
  @State private var lastTapMessage: String = "Tap anywhere on the map or on a Place POI."
  @State private var placeInfoEnabled: Bool = true

  var body: some View {
    VStack(spacing: 0) {
      ZStack(alignment: .top) {
        Map(initialCamera: .sanFrancisco, mode: .hybrid)
          .placeInformationEnabled(placeInfoEnabled)
          .onPlaceTap { placeId in
            lastTapMessage = "GoogleMaps3DKit onPlaceTap: \(placeId)"
            return .default
          }
          .onTap { tapInfo in
            switch tapInfo.content {
            case .map:
              lastTapMessage = String(
                format: "Map tapped at %.4f, %.4f (alt: %.0fm)",
                tapInfo.location.latitude,
                tapInfo.location.longitude,
                tapInfo.location.altitude
              )
            case .place(let placeId):
              // When placeInfoEnabled is true, .onPlaceTap handles the place tap event and
              // opens the built-in Place Details sheet. Avoid overwriting its message here.
              if !placeInfoEnabled {
                lastTapMessage = "Map.onTap(.place): \(placeId)"
              }
            default:
              lastTapMessage = "Unknown tap"
            }
          }

        // Non-blocking banner so the built-in GoogleMaps3DKit Place Details sheet can present freely
        Text(lastTapMessage)
          .font(.caption.monospaced())
          .padding(.horizontal, 12)
          .padding(.vertical, 8)
          .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
          .padding(.top, 12)
          .padding(.horizontal, 16)
      }

      HStack {
        Toggle("Place Information Enabled", isOn: $placeInfoEnabled)
      }
      .padding()
      .background(.ultraThinMaterial)
    }
    .navigationTitle("Map Tap Demo")
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  MapTapDemo()
}
