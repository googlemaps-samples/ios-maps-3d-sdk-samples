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

struct CloudBasedMapStylingDemo: View {
  @State private var mode: MapMode = .roadmap
  @State private var styleLoadError: Bool = false

  private let roadmapMapId: String = "f0c0fefe479f994a53950363"
  private let hybridMapId: String = "f0c0fefe479f994a93e70e90"

  private var activeMapId: String {
    switch mode {
    case .roadmap:
      return roadmapMapId
    case .hybrid, .satellite:
      return hybridMapId
    default:
      return roadmapMapId
    }
  }

  var body: some View {
    VStack(spacing: 12) {
      // https://developers.google.com/maps/documentation/get-map-id
      Map(initialCamera: .newYork, mode: mode)
        .style(mapID: activeMapId) {
          styleLoadError = true
        }

      VStack(spacing: 8) {
        Picker("Map Mode", selection: $mode) {
          Text("Roadmap").tag(MapMode.roadmap)
          Text("Hybrid").tag(MapMode.hybrid)
          Text("Satellite").tag(MapMode.satellite)
        }
        .pickerStyle(.segmented)

        if styleLoadError {
          Text("Failed to load cloud style for Map ID '\(activeMapId)'.")
            .font(.caption.bold())
            .foregroundColor(.red)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
      .padding(.horizontal)
      .padding(.bottom, 8)
    }
    .navigationTitle("Cloud Map Styling")
    .navigationBarTitleDisplayMode(.inline)
    .onChange(of: activeMapId) { _, _ in
      styleLoadError = false
    }
  }
}

#Preview {
  CloudBasedMapStylingDemo()
}
