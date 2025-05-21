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

struct ShapesDemo: View {
  @State var camera: Camera = .downtownSanFrancisco

  var body: some View {
    VStack {
      Map(camera: $camera, mode: .hybrid) {
        polyline
        originPolygon
        destinationPolygon
      }
    }
  }
}
 
var polyline: Polyline = .init(coordinates: [
    LatLngAltitude(latitude: 37.80515638571346, longitude: -122.4032569467164, altitude: 0),
    LatLngAltitude(latitude: 37.80337073509504, longitude: -122.4012878349353, altitude: 0),
    LatLngAltitude(latitude: 37.79925208843463, longitude: -122.3976697250461, altitude: 0),
    LatLngAltitude(latitude: 37.7989102378512, longitude: -122.3983408725656, altitude: 0),
    LatLngAltitude(latitude: 37.79887832784348, longitude: -122.3987094864192, altitude: 0),
    LatLngAltitude(latitude: 37.79786443410338, longitude: -122.4066878788802, altitude: 0),
    LatLngAltitude(latitude: 37.79549248916587, longitude: -122.4032992702785, altitude: 0),
    LatLngAltitude(latitude: 37.78861484290265, longitude: -122.4019489189814, altitude: 0),
    LatLngAltitude(latitude: 37.78618687561075, longitude: -122.398969592545, altitude: 0),
    LatLngAltitude(latitude: 37.7892310309145, longitude: -122.3951458683092, altitude: 0),
    LatLngAltitude(latitude: 37.7916358762409, longitude: -122.3981969390652, altitude: 0)
  ])
  .stroke(GoogleMaps3D.Polyline.StrokeStyle(
    strokeColor: UIColor(red: 0.09803921568627451, green: 0.403921568627451, blue: 0.8235294117647058, alpha: 1),
    strokeWidth: 10.0,
    outerColor: .white,
    outerWidth: 0.2
    ))
  .contour(GoogleMaps3D.Polyline.ContourStyle(isGeodesic: true))


  var originPolygon: Polygon = .init(outerCoordinates: [
    LatLngAltitude(latitude: 37.79165766856578, longitude:  -122.3983762901255, altitude: 300),
    LatLngAltitude(latitude: 37.7915324439261, longitude:  -122.3982171091383, altitude: 300),
    LatLngAltitude(latitude: 37.79166617650914, longitude:  -122.3980478493319, altitude: 300),
    LatLngAltitude(latitude: 37.79178986470217, longitude:  -122.3982041104199, altitude: 300),
    LatLngAltitude(latitude: 37.79165766856578, longitude:  -122.3983762901255, altitude: 300 )
  ],
  altitudeMode: .relativeToGround)
  .style(GoogleMaps3D.Polygon.StyleOptions(fillColor:.green, extruded: true) )

  var destinationPolygon: Polygon = .init(outerCoordinates: [
      LatLngAltitude(latitude: 37.80515661739527, longitude:  -122.4034307490334, altitude: 300),
      LatLngAltitude(latitude: 37.80503794515428, longitude:  -122.4032633416024, altitude: 300),
      LatLngAltitude(latitude: 37.80517850164195, longitude:  -122.4031056058006, altitude: 300),
      LatLngAltitude(latitude: 37.80529346901115, longitude:  -122.4032622466595, altitude: 300),
      LatLngAltitude(latitude: 37.80515661739527, longitude:  -122.4034307490334, altitude: 300 )
  ],
  altitudeMode: .relativeToGround)
  .style(GoogleMaps3D.Polygon.StyleOptions(fillColor:.red, extruded: true) )

#Preview {
  ShapesDemo()
}
