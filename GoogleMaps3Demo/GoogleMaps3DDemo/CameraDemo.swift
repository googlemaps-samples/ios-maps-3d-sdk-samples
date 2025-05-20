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

struct CameraDemo: View {
  @State var camera: Camera = .sanFrancisco
  @State private var animate: Bool = false
  @State private var flyAround: Bool = false

  var body: some View {
    VStack {
      Map(camera: $camera, mode: .hybrid)
        .flyCameraTo(
          .seattle,
          duration: 5,
          trigger: animate,
          completion: { flyAround = true }
        )
        .flyCameraAround(
          .seattle,
          duration: 15,
          rounds: 0.5,
          trigger: flyAround,
          callback: {  }
        )
      Button("Start Flying") {
        animate.toggle()
      }
    }
  }
}

#Preview {
  CameraDemo()
}
