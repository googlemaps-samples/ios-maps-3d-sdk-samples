// Copyright 2025 Google LLC
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

import SwiftUI
import GoogleMaps3D

struct ModelDemo: View {
  @State var camera: Camera = .sanFrancisco
  @State var balloonModel: Model = .init(
    position: .init(
      latitude: 37.791376,
      longitude: -122.397571,
      altitude: 300.0),
    url: URL(fileURLWithPath: fileUrl?.relativePath ?? ""),
    altitudeMode: .absolute,
    scale: .init(x: 5, y: 5, z: 5),
    orientation: .init(heading: 0, tilt: 0, roll: 0)
  )

  var body: some View {
    VStack {
      Map(camera: $camera, mode: .hybrid) {
        balloonModel
      }
    }
  }
}
private let fileUrl = Bundle.main.url(forResource: "balloon", withExtension: "glb")

#Preview {
  ModelDemo()
}
