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

struct MarkerStyleDemo: View {
  @State var markers: [MapEntity<Marker>] = [
    .init(content: randomMarker(camera: .sanFranciscoZoomedOut, style: .pin(.red)))
  ]

  @State var isShowingAlert: Bool = false
  @State var title: String = ""

  var body: some View {
    VStack {
      Map(initialCamera: .sanFranciscoZoomedOut, mode: .hybrid) {
        ForEach(markers) { marker in
          marker.content
            .onTap {
              title = "Marker tapped \(marker.id)"
              isShowingAlert = true
            }
        }
      }
      HStack {
        Spacer()
        Button {
          markers.append(
            .init(
              content:
                randomMarker(
                  camera: .sanFranciscoZoomedOut, style: .pin(.red))))
        } label: {
          Image(systemName: "pin.fill")
            .foregroundColor(.red)
        }
        Spacer()
        Button {
          markers.append(
            .init(
              content:
                randomMarker(
                  camera: .sanFranciscoZoomedOut, style: .pin(.init(backgroundColor: .yellow)))))
        } label: {
          Image(systemName: "pin.fill")
            .foregroundColor(.yellow)
        }
        Spacer()
        Button {
          markers.append(
            .init(
              content:
                randomMarker(
                  camera: .sanFranciscoZoomedOut,
                  style: .pin(
                    .init(backgroundColor: .green, borderColor: .brown) {
                      Text("G")
                        .minimumScaleFactor(0.01)
                    }))))
        } label: {
          Image(systemName: "text.bubble")
        }
        Spacer()
        Button {
          markers.append(
            .init(
              content:
                randomMarker(
                  camera: .sanFranciscoZoomedOut,
                  style: .viewSnapshot {
                    Image(systemName: "plus")
                      .font(.system(size: 6))
                      .foregroundStyle(.orange)
                      .padding(2)
                      .border(Color.orange, width: 1)
                  })))
        } label: {
          Image(systemName: "puzzlepiece.extension")
        }
        Spacer()
        Button {
          markers.append(
            .init(
              content:
                randomMarker(camera: .sanFranciscoZoomedOut, style: .image(Image(systemName: "plus")))))
        } label: {
          Image(systemName: "photo")
        }
        Spacer()
        Button {
          markers.append(
            .init(
              content:
                randomMarker(
                  camera: .sanFranciscoZoomedOut, style: .pin(.init(scale: 2.0)))))
        } label: {
          Image(systemName: "pin.fill")
            .foregroundColor(.blue)
            .scaleEffect(1.5)
        }
        Spacer()
      }
      .alert(isPresented: $isShowingAlert) {
        Alert(
          title: Text(title),
          dismissButton: .default(Text("OK"))
        )
      }
    }
  }
}

@MainActor
private func randomMarker(camera: Camera, style: Marker.Style) -> Marker {
  Marker(
    position: .init(
      latitude: camera.center.latitude + Double.random(in: 0...0.1) - 0.05,
      longitude: camera.center.longitude + Double.random(in: 0...0.1) - 0.05,
      altitude: 0.0),
    altitudeMode: .absolute,
    collisionBehavior: .required,
    extruded: false,
    drawsWhenOccluded: true,
    sizePreserved: true,
    zIndex: 0,
    label: "Test",
    style: style)
}

#Preview {
  MarkerStyleDemo()
}
