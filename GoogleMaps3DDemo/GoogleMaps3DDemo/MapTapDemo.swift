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
  @State var camera: Camera = .sanFrancisco
  @State var isPresented = false
  @State var tapInfo: MapTapInfo?
  @State var alertMessage: String = ""
  @State var placeInfoEnabled: Bool = true

  var body: some View {
    VStack(spacing: 0) {
      Map(camera: $camera, mode: .hybrid)
        .placeInformationEnabled(placeInfoEnabled)
        .onPlaceTap { placeId in
          alertMessage = "GoogleMaps3DKit onPlaceTap: \(placeId)"
          isPresented = true
          return .default
        }
        .onTap { tapInfo in
          self.tapInfo = tapInfo
          isPresented = true
          switch tapInfo.content {
            case .map:
              alertMessage = "Map tapped at \(String(format: "%.4f, %.4f", tapInfo.location.latitude, tapInfo.location.longitude))"
            case .place(let placeId):
              alertMessage = "Place tapped: \(placeId)"
            default:
              alertMessage = "Unknown tap"
          }
        }
        .alert(
          alertMessage,
          isPresented: $isPresented,
          actions: { Button("OK") {} }
        )

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
