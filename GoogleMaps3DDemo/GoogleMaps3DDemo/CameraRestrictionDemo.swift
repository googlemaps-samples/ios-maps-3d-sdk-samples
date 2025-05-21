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

import GoogleMaps3D
import SwiftUI

struct CameraRestrictionDemo: View {
  @State var camera:Camera = .init(
    latitude: 37.7905,
    longitude: -122.3989,
    heading: 279,
    tilt: 71,
    range: 2500
  )

  var body: some View {
    Map(camera: $camera, mode: .hybrid)
      .cameraRestrictions([
        .bounds(latitude: 37.7...37.8, longitude: (-122.4)...(-122.3)),
        .altitude(1000...10000),
        .heading(90...300),
        .tilt(30...90)
      ])
  }
}

#Preview {
  CameraRestrictionDemo()
}
