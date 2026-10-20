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

struct ModelDemo: View {
  private static let balloonModelUrl = Bundle.main.url(
    forResource: "balloon",
    withExtension: "glb"
  )

  @State private var isShowingAlert: Bool = false

  var body: some View {
    VStack {
      Map(initialCamera: .sanFrancisco, mode: .hybrid) {
        if let url = Self.balloonModelUrl {
          Model(
            position: .init(
              latitude: 37.791376,
              longitude: -122.397571,
              altitude: 300.0
            ),
            url: url,
            altitudeMode: .absolute,
            scale: .init(x: 5, y: 5, z: 5),
            orientation: .init(heading: 0, tilt: 0, roll: 0)
          )
          .onTap {
            isShowingAlert = true
          }
        }
      }
      .alert("3D Balloon Model Tapped", isPresented: $isShowingAlert) {
        Button("OK", role: .cancel) {}
      } message: {
        Text("You tapped the 3D balloon model above San Francisco.")
      }
    }
    .navigationTitle("Model Demo")
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  ModelDemo()
}
