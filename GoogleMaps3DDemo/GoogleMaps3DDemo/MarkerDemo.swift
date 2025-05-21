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

struct MarkerDemo: View {
  @State var camera: Camera = .sanFrancisco
  @State var mapMarker: Marker = .init(
    position: .init(
      latitude: 37.8044862,
      longitude: -122.4301493,
      altitude: 0.0),
    altitudeMode: .absolute,
    collisionBehavior: .required,
    extruded: false,
    drawsWhenOccluded: true,
    sizePreserved: true,
    zIndex: 0,
    label: "Test"
  )

  @State var extrudedMarker: Marker = .init(
    position: .init(
      latitude: 37.78980534,
      longitude:  -122.3969349,
      altitude: 50.0),
    altitudeMode: .relativeToMesh,
    collisionBehavior: .required,
    extruded: true,
    drawsWhenOccluded: true,
    sizePreserved: true,
    zIndex: 0,
    label: "Extruded"
  )

  var body: some View {
    VStack {
      Map(camera: $camera, mode: .hybrid) {
        mapMarker
        extrudedMarker
      }
    }
  }
}

#Preview {
  MarkerDemo()
}
