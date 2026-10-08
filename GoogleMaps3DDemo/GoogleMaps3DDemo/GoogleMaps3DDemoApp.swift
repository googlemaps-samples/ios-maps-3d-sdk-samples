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

import SwiftUI
import GoogleMaps3D
import GoogleMaps3DKit

@main
struct GoogleMaps3DDemoApp: App {
  @State private var isAdvancedDemosExpanded: Bool = false

  var body: some Scene {
    WindowGroup {
      NavigationView {
        List {
          NavigationLink(destination: ContentView()) {
            Text("Basic Map")
          }
          NavigationLink(destination: CameraControlsDemo()) {
            Text("Camera Controls Demo")
          }
          NavigationLink(destination: CameraDemo()) {
            Text("Camera Demo")
          }
          NavigationLink(destination: CameraRestrictionDemo()) {
            Text("Camera Restrictions Demo")
          }
          NavigationLink(destination: CloudBasedMapStylingDemo()) {
            Text("Cloud Based Map Styling Demo")
          }
          NavigationLink(destination: FieldOfViewDemo()) {
            Text("Field of View Demo")
          }
          NavigationLink(destination: FloodFillDemo()) {
            Text("Flood Fill Demo")
          }
          NavigationLink(destination: MapControlsDemo()) {
            Text("Map Controls Demo")
          }
          NavigationLink(destination: MapTapDemo()) {
            Text("Map Tap Demo")
          }
          NavigationLink(destination: MarkerCollisionDemo()) {
            Text("Marker Collision Demo")
          }
          NavigationLink(destination: MarkerDemo()) {
            Text("Marker Demo")
          }
          NavigationLink(destination: MarkerStyleDemo()) {
            Text("Marker Style Demo")
          }
          NavigationLink(destination: ModelDemo()) {
            Text("Model Demo")
          }
          NavigationLink(destination: PlacesUIKitDemo()) {
            Text("Places UI Kit Demo")
          }
          NavigationLink(destination: PopoverDemo()) {
            Text("Popover Demo")
          }
          NavigationLink(destination: RoadmapModeDemo()) {
            Text("Roadmap Mode Demo")
          }
          NavigationLink(destination: RoutesAPIDemo()) {
            Text("Routes API Demo")
          }
          NavigationLink(destination: ShapesDemo()) {
            Text("Shapes Demo")
          }

          DisclosureGroup(isExpanded: $isAdvancedDemosExpanded) {
            NavigationLink(destination: CityNavigationDemo()) {
              Text("City Navigation Demo")
            }
            NavigationLink(destination: FlyAlongRouteDemo()) {
              Text("Flight Path Demo")
            }
            NavigationLink(destination: FlightSimulatorDemo()) {
              Text("Flight Simulator Demo")
            }
            NavigationLink(destination: OutdoorActivityDemo()) {
              Text("Outdoor Activity Demo")
            }
          } label: {
            Text("Advanced demos")
          }
        }
        .navigationTitle("Maps 3D SDK Samples")
      }

      .onAppear {
        // Read the API key from the app bundle. Create a Secrets.xcconfig next to
        // GoogleMaps3DDemo.xcconfig (git-ignored) with `MAPS_API_KEY = <your key>`;
        // the tracked GoogleMaps3DDemo.xcconfig wrapper includes it. See README for setup.
        guard let infoDictionary: [String: Any] = Bundle.main.infoDictionary else {
          fatalError("Info.plist not found")
        }
        guard let apiKey: String = infoDictionary["MAPS_API_KEY"] as? String,
              !apiKey.isEmpty,
              apiKey != "your_api_key_here" else {
          fatalError(
            "Add MAPS_API_KEY to Secrets.xcconfig next to GoogleMaps3DDemo.xcconfig. "
            + "Get a key at https://developers.google.com/maps/documentation/maps-3d/ios-sdk/setup#create-project")
        }
        Map.apiKey = apiKey
      }
    }
  }
}
