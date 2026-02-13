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

@MainActor
struct FlyAlongRouteDemo: View {
  @State private var camera: Camera = .innsbruck
  @State private var flyToDuration: TimeInterval = 5
  @State var animation: Bool = true

  @StateObject var flightData: FlightDataLoader = FlightDataLoader()

  var body: some View {
    VStack {
      if let first = flightData.flightPathData.flight.first {
        Map(camera: $camera, mode: .hybrid)
          .keyframeAnimator(
            initialValue: makeCamera(step: first),
            trigger: animation,
            content: { view, value in
              Map(camera: .constant(value), mode: .hybrid)
            },
            keyframes: { _ in
              KeyframeTrack {
                let steps = flightData.flightPathData.flight
                //if steps.count > 1 {
                  for i in 2..<steps.count {
                    makeKeyFrame(step: steps[i])
                  }
                //}
              }
            }
          )
      } else {
        // Optional: placeholder while data loads
        Map(camera: $camera, mode: .hybrid)
      }

      Button("Fly Along Route"){
        animation.toggle()
      }
    }
  }

  func makeKeyFrame(step: FlightPathLocation) -> CubicKeyframe<Camera> {
    return CubicKeyframe(
      makeCamera(step: step),
      duration: flyToDuration
    )
  }

  func makeCamera(step: FlightPathLocation) -> Camera {
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
