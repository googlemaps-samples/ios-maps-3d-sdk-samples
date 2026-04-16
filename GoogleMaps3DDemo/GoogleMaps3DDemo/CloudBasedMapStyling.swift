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
  @State private var camera: Camera = .newYork
  @State private var mode: MapMode = .roadmap

  let roadmapMapId: String = "f0c0fefe479f994a53950363"
  let hybridMapId: String = "f0c0fefe479f994a93e70e90"

  var body: some View {
    VStack(spacing:20){
      Map(camera: $camera, mode: .roadmap)
        // https://developers.google.com/maps/documentation/get-map-id
        .style(mapID: roadmapMapId)
    }
  }
}
