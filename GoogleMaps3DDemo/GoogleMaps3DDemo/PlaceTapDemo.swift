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

struct PlaceTapDemo: View {
  @State var camera: Camera = .sanFrancisco
  @State var isPresented = false
  @State var tapInfo: PlaceTapInfo?

  var body: some View {
    Map(camera: $camera, mode: .hybrid)
      .onPlaceTap { tapInfo in
        self.tapInfo = tapInfo
        isPresented.toggle()
      }
      .alert(
        "Place tapped - \(tapInfo?.placeId ?? "nil")",
        isPresented: $isPresented,
        actions: { Button("OK") {} }
      )
  }
}
#Preview {
  PlaceTapDemo()
}

