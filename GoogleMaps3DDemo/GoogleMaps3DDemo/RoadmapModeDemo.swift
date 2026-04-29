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

struct RoadmapModeDemo: View {
  @State private var camera: Camera = .london
  @State private var mapMode: MapMode = .roadmap

  var body: some View {
    VStack{
      Map(camera: $camera, mode: mapMode)
      Picker("Map Mode", selection: $mapMode) {
        Text("Roadmap").tag(MapMode.roadmap)
        Text("Hybrid").tag(MapMode.hybrid)
        Text("Satellite").tag(MapMode.satellite)
      }
      .pickerStyle(.segmented)
      .padding()
    }
  }
}

