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
  @State var animation: Bool = true

  @StateObject var flightData: FlightDataLoader = FlightDataLoader()

  var body: some View {
    VStack {
      Map(camera: $camera, mode: .hybrid)
        .keyframeAnimator(
          initialValue: makeCamera(step: flightData.flightPathData.flight[0]),
          trigger: animation,
          content: { view, value in
            Map(camera: .constant(value), mode: .hybrid)
          },
          keyframes: { _ in
            KeyframeTrack(content: {
              for i in  1...flightData.flightPathData.flight.count-1 {
                makeKeyFrame(step: flightData.flightPathData.flight[i])
              }
            })
          }
        )
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
      latitude: step.latitude,
      longitude: step.longitude,
      altitude: step.altitude,
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
