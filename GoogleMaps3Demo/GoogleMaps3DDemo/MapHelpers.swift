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

extension Camera {
  //public static var sanFrancisco: Camera = .init(longitude: -122.08, latitude: 37.39)
  public static var sanFrancisco: Camera = .init(
    latitude: 37.7845812,
    longitude: -122.3660241,
    altitude: 585,
    heading: 288.0,
    tilt: 75.0,
    roll: 0.0,
    range: 100)

  public static var seattle: Camera = .init(
    latitude: 47.6210296,
    longitude: -122.3496903,
    heading: 149.0,
    tilt: 77.0,
    roll: 0.0,
    range: 4000)

  public static var downtownSanFrancisco: Camera = .init(
    latitude: 37.7957734,
    longitude: -122.4000130,
    heading: 25,
    tilt: 20,
    range: 4200)

  public static var innsbruck: Camera = .init(
    latitude: 47.263,
    longitude: 11.3704,
    altitude: 640.08,
    heading: 237,
    tilt: 80.0,
    roll: 0.0,
    range: 200)
}
