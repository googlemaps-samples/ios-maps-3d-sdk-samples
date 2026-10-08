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

/// Demonstrates the built-in UI map controls introduced in Maps 3D SDK v1.0.0,
/// including position placement, orientation customization, and individual control toggles.
struct MapControlsDemo: View {
  @State private var camera: Camera = .sanFrancisco
  @State private var position: MapControlPosition = .trailing
  @State private var orientation: MapControlOrientation = .auto

  @State private var showCompass: Bool = true
  @State private var showZoom: Bool = true
  @State private var showTilt: Bool = true
  @State private var showRotate: Bool = true
  @State private var showPanHorizontal: Bool = false
  @State private var showPanVertical: Bool = false

  var body: some View {
    VStack(spacing: 0) {
      Map(camera: $camera, mode: .hybrid)
        .mapControls(at: position, margin: 16, spacing: 8) {
          if showCompass {
            CompassControl()
          }
          if showZoom {
            ZoomControl(orientation: orientation)
          }
          if showTilt {
            TiltControl(orientation: orientation)
          }
          if showRotate {
            RotateControl(orientation: orientation)
          }
          if showPanHorizontal {
            PanHorizontalControl(orientation: orientation)
          }
          if showPanVertical {
            PanVerticalControl(orientation: orientation)
          }
        }

      // Configuration controls sheet
      VStack(spacing: 12) {
        HStack {
          Text("Position:")
            .font(.subheadline.bold())
          Picker("Position", selection: $position) {
            Text("Trailing").tag(MapControlPosition.trailing)
            Text("Leading").tag(MapControlPosition.leading)
            Text("Top").tag(MapControlPosition.top)
            Text("Bottom").tag(MapControlPosition.bottom)
          }
          .pickerStyle(.segmented)
        }

        HStack {
          Text("Orientation:")
            .font(.subheadline.bold())
          Picker("Orientation", selection: $orientation) {
            Text("Auto").tag(MapControlOrientation.auto)
            Text("Vertical").tag(MapControlOrientation.vertical)
            Text("Horizontal").tag(MapControlOrientation.horizontal)
          }
          .pickerStyle(.segmented)
        }

        Divider()

        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            Toggle("Compass", isOn: $showCompass)
              .toggleStyle(.button)
            Toggle("Zoom", isOn: $showZoom)
              .toggleStyle(.button)
            Toggle("Tilt", isOn: $showTilt)
              .toggleStyle(.button)
            Toggle("Rotate", isOn: $showRotate)
              .toggleStyle(.button)
            Toggle("Pan H", isOn: $showPanHorizontal)
              .toggleStyle(.button)
            Toggle("Pan V", isOn: $showPanVertical)
              .toggleStyle(.button)
          }
        }
      }
      .padding()
      .background(.ultraThinMaterial)
    }
    .navigationTitle("Map Controls Demo")
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  MapControlsDemo()
}
