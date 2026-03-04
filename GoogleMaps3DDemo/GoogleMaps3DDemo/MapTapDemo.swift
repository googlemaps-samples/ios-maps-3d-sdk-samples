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

struct MapTapDemo: View {
  @State var camera: Camera = .sanFrancisco
  @State var isPresented = false
  @State var tapInfo: MapTapInfo?
  @State var alertMessage: String = ""

  var body: some View {
    Map(camera: $camera, mode: .hybrid)
      .onTap { tapInfo in
        self.tapInfo = tapInfo
        isPresented = true
        switch tapInfo.content {
          case .map:
            alertMessage = "Map tapped"
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
  }
}
#Preview {
  MapTapDemo()
}
