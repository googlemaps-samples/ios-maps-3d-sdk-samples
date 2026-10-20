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

struct MarkerDemo: View {
  @State private var tappedLabel: String?

  // Static Marker3Ds cached outside body to avoid repeated ImageRenderer PNG rasterization
  private let clampedMarker3D = Marker3D(
    position: .init(
      latitude: 37.8044862,
      longitude: -122.4301493,
      altitude: 0.0
    ),
    altitudeMode: .clampToGround,
    collisionBehavior: .required,
    extruded: false,
    drawsWhenOccluded: true,
    sizePreserved: true,
    zIndex: 0,
    label: "Clamped Marker3D"
  )

  private let extrudedMarker3D = Marker3D(
    position: .init(
      latitude: 37.78980534,
      longitude: -122.3969349,
      altitude: 120.0
    ),
    altitudeMode: .relativeToMesh,
    collisionBehavior: .required,
    extruded: true,
    drawsWhenOccluded: true,
    sizePreserved: true,
    zIndex: 0,
    label: "Extruded Marker3D (120m)",
    style: .pin(.init(backgroundColor: .orange))
  )

  var body: some View {
    ZStack(alignment: .bottom) {
      Map(initialCamera: .sanFranciscoZoomedOut, mode: .hybrid) {
        // 1. Static 3D markers (Marker3D)
        clampedMarker3D
          .onTap {
            tappedLabel = "Tapped Clamped Marker3D"
          }

        extrudedMarker3D
          .onTap {
            tappedLabel = "Tapped Extruded Marker3D"
          }

        // 2. SwiftUI Marker with default Pin() view
        Marker(
          position: .init(latitude: 37.7955, longitude: -122.3937, altitude: 0),
          altitudeMode: .clampToGround,
          collisionBehavior: .required
        )

        // 3. SwiftUI Marker with customized Pin(configuration:)
        Marker(
          position: .init(latitude: 37.8024, longitude: -122.4058, altitude: 20),
          altitudeMode: .relativeToMesh,
          collisionBehavior: .requiredAndHidesOptional,
          collisionPriority: 100
        ) {
          Pin(
            configuration: .init(backgroundColor: .indigo, borderColor: .white) {
              Image(systemName: "binoculars.fill")
                .foregroundStyle(.white)
            }
          )
          .onTapGesture {
            tappedLabel = "Tapped Coit Tower Pin Marker"
          }
        }

        // 4. SwiftUI Marker with custom live SwiftUI view content
        Marker(
          position: .alcatrazIsland,
          altitudeMode: .relativeToGround,
          collisionBehavior: .optionalAndHidesLowerPriority,
          collisionPriority: 50
        ) {
          HStack(spacing: 6) {
            Image(systemName: "ferry.fill")
              .foregroundStyle(.white)
            Text("Alcatraz")
              .font(.caption.bold())
              .foregroundStyle(.white)
          }
          .padding(.horizontal, 10)
          .padding(.vertical, 6)
          .background(.blue, in: Capsule())
          .shadow(radius: 4)
          .onTapGesture {
            tappedLabel = "Tapped Custom SwiftUI Marker (Alcatraz)"
          }
        }
      }

      if let tappedLabel {
        Text(tappedLabel)
          .font(.footnote.bold())
          .padding(.horizontal, 14)
          .padding(.vertical, 8)
          .background(.ultraThinMaterial, in: Capsule())
          .padding(.bottom, 16)
      }
    }
    .navigationTitle("Marker Demo")
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  MarkerDemo()
}
