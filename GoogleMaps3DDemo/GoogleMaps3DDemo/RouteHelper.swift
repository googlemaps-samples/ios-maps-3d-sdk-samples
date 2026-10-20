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

import Foundation
import GoogleMaps3D
import SwiftUI

public enum RouteServiceError: LocalizedError {
  case missingAPIKey
  case apiError(String)
  case emptyRoute

  public var errorDescription: String? {
    switch self {
    case .missingAPIKey:
      return "No Routes API key is configured. Set MAPS_API_KEY in Secrets.xcconfig or set RouteHelper.routesApiKey."
    case .apiError(let message):
      return "Routes API error: \(message). Ensure the Routes API is enabled on your Google Cloud project."
    case .emptyRoute:
      return "No route was returned for the requested origin and destination."
    }
  }
}

public class RouteHelper: ObservableObject {
  // Add an API Key here if you don't want to use the same key for Maps and Routes
  public var routesApiKey: String = ""

  /// Fetches the route from the Google Maps Platform Routes API.
  public func fetchRoute(origin: LatLngAltitude, destination: LatLngAltitude) async throws
    -> [LatLngAltitude]
  {
    let apiKey = routesApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !apiKey.isEmpty else {
      throw RouteServiceError.missingAPIKey
    }
    let url = URL(string: "https://routes.googleapis.com/directions/v2:computeRoutes")!

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
    // Request only the encoded polyline to minimize payload
    request.setValue("routes.polyline.encodedPolyline", forHTTPHeaderField: "X-Goog-FieldMask")

    let body: [String: Any] = [
      "origin": [
        "location": [
          "latLng": [
            "latitude": origin.latitude,
            "longitude": origin.longitude,
          ]
        ]
      ],
      "destination": [
        "location": [
          "latLng": [
            "latitude": destination.latitude,
            "longitude": destination.longitude,
          ]
        ]
      ],
      "travelMode": "DRIVE",
    ]

    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (data, response) = try await URLSession.shared.data(for: request)

    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
      if let errorDict = json["error"] as? [String: Any],
        let message = errorDict["message"] as? String
      {
        throw RouteServiceError.apiError(message)
      }

      if let routes = json["routes"] as? [[String: Any]],
        let firstRoute = routes.first,
        let polyline = firstRoute["polyline"] as? [String: Any],
        let encodedPolyline = polyline["encodedPolyline"] as? String
      {
        let decoded = processRoute(encodedPolyline: encodedPolyline)
        guard !decoded.isEmpty else {
          throw RouteServiceError.emptyRoute
        }
        return decoded
      }
    }

    if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
      throw RouteServiceError.apiError("HTTP \(httpResponse.statusCode)")
    }

    throw RouteServiceError.emptyRoute
  }

  /// Processes the encoded polyline string from the Routes API.
  private func processRoute(encodedPolyline: String) -> [LatLngAltitude] {
    // The Routes API returns a 2D polyline; .latLng decoding initializes altitude to 0.0
    guard let path2D = [LatLngAltitude](encodedPath: encodedPolyline, dimensions: .latLng) else {
      return []
    }
    return path2D
  }

  /// Calculates a Camera view that contains the entire route shape.
  public func calculateCamera(for path: [LatLngAltitude]) -> Camera? {
    guard !path.isEmpty else { return nil }

    var minLat = path[0].latitude
    var maxLat = path[0].latitude
    var minLng = path[0].longitude
    var maxLng = path[0].longitude

    for point in path {
      minLat = min(minLat, point.latitude)
      maxLat = max(maxLat, point.latitude)
      minLng = min(minLng, point.longitude)
      maxLng = max(maxLng, point.longitude)
    }

    let centerLat = (minLat + maxLat) / 2.0
    let centerLng = (minLng + maxLng) / 2.0

    // Rough estimation for range based on bounds (1 degree of latitude is approx 111km)
    let latDelta = maxLat - minLat
    let lngDelta = maxLng - minLng
    let maxDelta = max(latDelta, lngDelta)

    let range = maxDelta * 111_000 * 2.0
    let safeRange = max(range, 400)

    return Camera(
      center: LatLngAltitude(latitude: centerLat, longitude: centerLng, altitude: 0),
      heading: 0,
      tilt: 65.0,
      range: safeRange
    )
  }
}
