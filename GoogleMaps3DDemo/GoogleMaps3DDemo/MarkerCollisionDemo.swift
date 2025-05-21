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

struct MarkerCollisionDemo: View {
  @State var sanFrancisco: Camera = .init(latitude: 37.79556672721526, longitude: -122.39345183225336, altitude: 50, heading: 226.0, tilt: 75.0, roll: 0.0, range: 500)


  var body: some View {
    VStack {
      Map(camera: $sanFrancisco, mode: .hybrid) {
        Marker(
          position: .init(
            latitude: 37.794724,
            longitude:  -122.39442,
            altitude: 100.0),
          altitudeMode: .relativeToMesh,
          collisionBehavior: .optionalAndHidesLowerPriority,
          extruded: true,
          label: "Marker 1"
        )
        Marker(
          position: .init(
            latitude: 37.7943220,
            longitude: -122.395073,
            altitude: 100.0),
          altitudeMode: .relativeToMesh,
          collisionBehavior: .required,
          extruded: true,
          label: "Marker 2"
        )

        Marker(
          position: .init(
            latitude: 37.7934108,
            longitude: -122.396144,
            altitude: 100.0),
          altitudeMode: .relativeToMesh,
          collisionBehavior: .requiredAndHidesOptional,
          extruded: true,
          label: "Marker 3"
        )

      }

    }
  }
}



#Preview {
  MarkerCollisionDemo()
}
