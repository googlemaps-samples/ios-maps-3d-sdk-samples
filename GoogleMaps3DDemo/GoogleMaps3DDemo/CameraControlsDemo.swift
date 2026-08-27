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

struct CameraControlsDemo: View {
  @State private var camera: Camera = .devilsTower

  var body: some View {
    VStack(spacing: 12) {
      Map(camera: $camera, mode: .hybrid)

      VStack(spacing: 8) {
        controlRow(
          title: "Heading",
          value: $camera.heading,
          range: -360...360,
          step: 10,
          specifier: "%.0f°"
        )
        controlRow(
          title: "Range",
          value: $camera.range,
          range: 500...40000,
          step: 500,
          specifier: "%.0fm"
        )
        controlRow(
          title: "Tilt",
          value: $camera.tilt,
          range: 0...85,
          step: 5,
          specifier: "%.1f°"
        )
        controlRow(
          title: "Roll",
          value: $camera.roll,
          range: -180...180,
          step: 10,
          specifier: "%.0f°"
        )

        Button("Reset Camera") {
          camera = .devilsTower
        }
        .buttonStyle(.bordered)
        .padding(.top, 4)
      }
      .padding(.horizontal)
      .padding(.bottom, 8)
      .background(.ultraThinMaterial)
    }
    .navigationTitle("Camera Controls")
  }

  private func controlRow(
    title: String,
    value: Binding<Double>,
    range: ClosedRange<Double>,
    step: Double,
    specifier: String
  ) -> some View {
    HStack {
      Text(title)
        .frame(width: 70, alignment: .leading)
        .font(.caption.bold())

      Slider(
        value: value,
        in: range,
        step: step
      )

      Text(String(format: specifier, value.wrappedValue))
        .frame(width: 65, alignment: .trailing)
        .font(.caption.monospacedDigit())
    }
  }
}

#Preview {
  CameraControlsDemo()
}
