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

struct FlyAlongRouteDemo: View {
  @State private var camera: Camera = .innsbruck
  @State private var flyToDuration: TimeInterval = 5
  @State private var animation: Bool = false

  @StateObject private var flightData = FlightDataLoader()

  private var initialCamera: Camera {
    if let firstStep = flightData.flightPathData.flight.first {
      return makeCamera(step: firstStep)
    }
    return .innsbruck
  }

  var body: some View {
    VStack {
      if !flightData.flightPathData.flight.isEmpty {
        Map(camera: $camera, mode: .hybrid)
          .keyframeAnimator(
            initialValue: initialCamera,
            trigger: animation
          ) { _, value in
            Map(camera: .constant(value), mode: .hybrid)
          } keyframes: { _ in
            KeyframeTrack {
              for step in flightData.flightPathData.flight.dropFirst() {
                CubicKeyframe(
                  makeCamera(step: step),
                  duration: flyToDuration
                )
              }
            }
          }
      } else {
        Map(camera: $camera, mode: .hybrid)
      }

      Button("Fly Along Route") {
        animation.toggle()
      }
      .padding()
    }
  }

  private func makeCamera(step: FlightPathLocation) -> Camera {
    return .init(
      center: .init(latitude: step.latitude, longitude: step.longitude, altitude: step.altitude),
      heading: step.bearing,
      tilt: 75,
      roll: 0,
      range: 200
    )
  }
}

#Preview {
  FlyAlongRouteDemo()
}
