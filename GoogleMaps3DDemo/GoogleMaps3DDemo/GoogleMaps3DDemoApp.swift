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
          NavigationLink(destination: ContentView()) {
            Text("Basic Map")
          }
          NavigationLink(destination: CameraDemo()) {
            Text("Camera Demo")
          }
          NavigationLink(destination: CameraRestrictionDemo()) {
            Text("Camera Restrictions Demo")
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
            Text("Flight Path Demo")
          }
          NavigationLink(destination: MarkerCollisionDemo()) {
            Text("Marker Collision Demo")
          }
        }
      }

      .onAppear {
        /*
         API Key Setup:
         1. Get an API key using teh instructions at: https://developers.google.com/maps/documentation/maps-3d/ios-sdk/setup#create-project
         2. Create a .xcconfig file at the project root level
         3. Add this line: MAPS_API_KEY = your_api_key_here
         4. Replace "your_api_key_here" with the API key obtained in step 3

         Note: Never commit your actual API key to source control
        */
        guard let infoDictionary: [String: Any] = Bundle.main.infoDictionary else {
          fatalError("Info.plist not found")
        }
        guard let apiKey: String = infoDictionary["MAPS_API_KEY"] as? String else {
          fatalError("MAPS_API_KEY not set in Info.plist")
        }
        Map.apiKey = apiKey
      }
    }
  }
}
