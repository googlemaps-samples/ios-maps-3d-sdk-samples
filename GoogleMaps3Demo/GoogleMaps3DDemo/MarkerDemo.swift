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

struct MarkerDemo: View {
  @State var camera: Camera = .sanFrancisco
  @State var mapMarker: Marker = .init(
    position: .init(
      latitude: 37.8044862,
      longitude: -122.4301493,
      altitude: 0.0),
    altitudeMode: .absolute,
    collisionBehavior: .required,
    extruded: false,
    drawsWhenOccluded: true,
    sizePreserved: true,
    zIndex: 0,
    label: "Test"
  )

  @State var extrudedMarker: Marker = .init(
    position: .init(
      latitude: 37.78980534,
      longitude:  -122.3969349,
      altitude: 50.0),
    altitudeMode: .relativeToMesh,
    collisionBehavior: .required,
    extruded: true,
    drawsWhenOccluded: true,
    sizePreserved: true,
    zIndex: 0,
    label: "Extruded"
  )

  var body: some View {
    VStack {
      Map(camera: $camera, mode: .hybrid) {
        mapMarker
        extrudedMarker
        customMarker()
      }
    }
  }
}


private let googleMapsPin =
"data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAYAAABXAvmHAAAEx0lEQVR4Ae2YA3RcWxRAbxHXtu12kE5sezK1bdsKvmtbg9q2bduxrfPPK+9Kh8mwq3utHWOfO8/k1+E3UKTK6E/21cZELECPVBsb8QBNRDPQV1XHRlyuOu7TP00mR/uwVoAR0RfqTYwrjYFh1cZGvsP3IM+a4yMT7Ocl5ziFpHxwCk2dZhuaXJHoElzpjriyHxWFM9YYF5FrPScJMJ42zjkkuRPRNqwBYIRRIhSUsfq4CLCcmcAEy1LI+xfMiDZoMPyZCUbtRUFZ28yIlx5O6RyScthzIZgQTQKzSNF+fYUiVeKbTYlVGE8NsV8ggWJEU0Q5cSdGOXNyJndbmqNMfIOJ0eDIxKkg/vx4ogkinS1bRTpzMnEAYFwpmAK1xryXGV9nfBQ4zEtmolQ1zXVuYkOibjB6Owq0B/16Q9ORz6QccSLzbOaqFk9rtXzZVqJOYtxYTTA4F4X83vDyB+th138MgIfL9jMTM5xCknc6haTO/Oo2DEtRJt56iTCDLeLncbbym6tz9UNRkOVLN/vcoAGHPg/QcmrcKefQpPIkH8xJyyk0Zau8eNv5Z4At5ufhAMAR88PVN4AL57q0cNpIZ27O7EH/LSUKcAxJXi4t3uHvh8ARdgGM/+ZDog4SbGzKytp8aGO7Nn8FEqLwZCSYBcYY/IqOdwx/D9zNA5ho2jyWRFCaFJZIR25rhfEdW2Zn7jGdRpQEoyd+HyA0DizXj/8eTsuVCHiFH8DJ0k1efIxfG8jcaQ5ZJ40siZK4zEuy+TJAMvBW/8nESpUlDPJWx8lLICs+2p0F6RtLQ/bx4pBx0qQxURI847ZiBrBeullm/NcduUPhB3Bke0kdwIUDqQsrMfHfdFF6gNBUH9sFJzAyWNEAvmo4A3N50gZImlGTjmecT5TEfv7pXWxRh2wqVqrtREHtSWFJdOeVyx+fMKwBZB+j4z+bmn7KtA5RAG/ZwrYcYac4RfFoXluJoKK6TmRvqcMlZB0ypsNpb8NxUpnI4Oi+Gg15osD7CuOp84CaBuCuYeJj/NvkZO42o4Kl+j7ruFFfOEIsyFfgPCmZesxkcO/tju+oQEUuUuNlNNszyoWdkbG5JBWq0PSc48Weoy/w46z5e1pTcYrlbA30UOuNTOqiipeoOJXcs7+uSvHoQwKkCFEnuJLdChJ/7VBlwO1epQFYouB+RN0ArggG3VAl/s2RUuAi8VF19e+xVgwwIpoAo3hojjLx8cfMIHibm6rxuWxxkDXRJBg3W1F85nEjGLbDlgpT15FHDcApUhwjL8obIHxPu4LE32xw0NOEaAM4QapjaIS0ePH+hgWJT7Tcwm9ItEn2ieJ2GJxFx184WBW4oqA8FePzWGJ+ANEFeMYd8S3++ZEyYCsKyFIxHjjC4LlEl2QdM9oYc8w810XsE6tqPHqEzJpVlOgSOEVMA7e5HyxA/FvW1s4ViD7QThTYFIPSVIjPpq/19QK2kD9U6QGEwbOIPoJxB5QY4JrDKYfiRB/hSARVMDBRTnwW9chQP2GJg8bKvsrkzyf6DnM5gLGfpAyQSh919P1VmPbzjstfRgwFlkRQC6Nz6QE4oiAOMSQ4Iv4laoAXxNDA6PEoUM/6DQueRFAOjzoP0KdthX7VyG9+Uf4HhI7Fcg3HuQQAAAAASUVORK5CYII="

func customMarker() -> Marker {
  var newMarker: Marker =  .init(
    position: .init(
      latitude: 37.7895028,
      longitude:  -122.3854021,
      altitude: 100.0),
    //url: URL(string: markerImage),
    altitudeMode: .relativeToGround,
    collisionBehavior: .required,
    extruded: true,
    drawsWhenOccluded: true,
    sizePreserved: true,
    zIndex: 0,
    label: "Custom"
  )

  newMarker.url = URL(string: googleMapsPin) ?? URL(fileURLWithPath: "")
  return newMarker
}
