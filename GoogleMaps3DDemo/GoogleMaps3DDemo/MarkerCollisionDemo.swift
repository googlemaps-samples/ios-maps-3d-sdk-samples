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

struct MarkerCollisionDemo: View {
  private static let initialCamera = Camera(
    center: .init(latitude: 37.79556672721526, longitude: -122.39345183225336, altitude: 50),
    heading: 226.0,
    tilt: 75.0,
    roll: 0.0,
    range: 500
  )

  // Cache static Marker3Ds outside body so panning does not re-rasterize PNG textures
  private let optionalMarker3D = Marker3D(
    position: .init(latitude: 37.794724, longitude: -122.39442, altitude: 100.0),
    altitudeMode: .relativeToMesh,
    collisionBehavior: .optionalAndHidesLowerPriority,
    extruded: true,
    label: "Optional Marker3D"
  )

  private let requiredMarker3D = Marker3D(
    position: .init(latitude: 37.7943220, longitude: -122.395073, altitude: 100.0),
    altitudeMode: .relativeToMesh,
    collisionBehavior: .required,
    extruded: true,
    label: "Required Marker3D"
  )

  private let requiredHidesOptionalMarker3D = Marker3D(
    position: .init(latitude: 37.7934108, longitude: -122.396144, altitude: 100.0),
    altitudeMode: .relativeToMesh,
    collisionBehavior: .requiredAndHidesOptional,
    extruded: true,
    label: "Required & Hides Optional"
  )

  var body: some View {
    VStack {
      Map(initialCamera: Self.initialCamera, mode: .hybrid) {
        optionalMarker3D
        requiredMarker3D
        requiredHidesOptionalMarker3D

        // SwiftUI Markers demonstrating collisionPriority ordering
        Marker(
          position: .init(latitude: 37.7952, longitude: -122.3938, altitude: 60.0),
          altitudeMode: .relativeToMesh,
          collisionBehavior: .optionalAndHidesLowerPriority,
          collisionPriority: 100
        ) {
          Pin(
            configuration: .init(backgroundColor: .green, borderColor: .white) {
              Text("P100")
                .font(.system(size: 7, weight: .bold))
                .foregroundStyle(.white)
            }
          )
        }

        Marker(
          position: .init(latitude: 37.7950, longitude: -122.3940, altitude: 60.0),
          altitudeMode: .relativeToMesh,
          collisionBehavior: .optionalAndHidesLowerPriority,
          collisionPriority: 10
        ) {
          Pin(
            configuration: .init(backgroundColor: .purple, borderColor: .white) {
              Text("P10")
                .font(.system(size: 7, weight: .bold))
                .foregroundStyle(.white)
            }
          )
        }
      }
    }
    .navigationTitle("Marker Collision")
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  MarkerCollisionDemo()
}
