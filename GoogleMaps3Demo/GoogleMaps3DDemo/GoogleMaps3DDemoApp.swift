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

@main
struct GoogleMaps3DDemoApp: App {
  var body: some Scene {
    WindowGroup {
      NavigationView {
        List {
          NavigationLink(destination: Map(mode: .hybrid)) {
            Text("Basic Map")
          }
          NavigationLink(destination: CameraDemo()) {
            Text("Camera Demo")
          }
          NavigationLink(destination: MarkerDemo()) {
            Text("Marker Demo")
          }
          NavigationLink(destination: ModelDemo()) {
            Text("Model Demo")
          }
          NavigationLink(destination: ShapesDemo()) {
            Text("Shapes Demo")
          }
          NavigationLink(destination: PlaceTapDemo()) {
            Text("Place Tap Demo")
          }
          NavigationLink(destination: FlyAlongRouteDemo()) {
            Text("Flight Path  Demo")
          }
        }
      }

      .onAppear {
        //Map.apiKey = "YOUR_API_KEY" //replace with your API Key
        //But DON'T check the API key into source control!
      }
    }
  }
}
