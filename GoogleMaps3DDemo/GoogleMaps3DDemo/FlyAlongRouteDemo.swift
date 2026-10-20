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

import CoreLocation
import GoogleMaps3D
import SwiftUI

struct FlyAlongRouteDemo: View {
  enum PlaybackMode: String, CaseIterable, Identifiable {
    case spline = "Spline"
    case keyframe = "Cubic Keyframe"

    var id: String { rawValue }
  }

  private static let defaultTimeline = FlightTimeline.loadDefault()

  // Initial flight origin (first coordinate on the flight path)
  private static let startPosition =
    defaultTimeline.points.first
    ?? LatLngAltitude(
      latitude: 47.3844,
      longitude: 11.8412,
      altitude: 2872.74
    )
  private static let startHeading: Double = defaultTimeline.steps.first?.bearing ?? 237.0

  private static let airplaneModelUrl = Bundle.main.url(
    forResource: "Airplane",
    withExtension: "glb"
  )

  // Pre-computed constant-speed timeline initialized upfront so the polyline and plane
  // render immediately at the start of the flight path on frame 0.
  @State private var flightTimeline: FlightTimeline = Self.defaultTimeline
  @State private var visibleRoutePoints: [LatLngAltitude] =
    Self.defaultTimeline.remainingPathPoints(forSegmentIndex: 0)
  @State private var activeSegmentIndex: Int = 0
  @State private var renderRevision: Int32 = 1

  // Playback & camera configuration
  @State private var playbackMode: PlaybackMode = .spline
  @State private var cameraMode: FlightCameraMode = .chase
  @State private var speedMultiplier: Double = 5.0
  @State private var showPlaneModel: Bool = false
  @State private var hasStartedFlight: Bool = false
  @State private var isAnimating: Bool = false

  // Continuous simulation state (parameterized by cumulative distance at constant speed)
  @State private var currentDistance: Double = 0.0
  @State private var lastFrameDate: Date?
  @State private var planePosition: LatLngAltitude = Self.startPosition
  @State private var planeHeading: Double = Self.startHeading
  @State private var planePitch: Double = 0.0
  @State private var planeRoll: Double = 0.0
  @State private var currentAirspeedKnots: Double = FlightTimeline.constantCruiseSpeedKnots

  private let planeScale: Double = 0.05

  @State private var camera: Camera = FlightCameraRig.routeCamera(
    mode: .chase,
    position: Self.startPosition,
    heading: Self.startHeading
  )

  var body: some View {
    VStack(spacing: 0) {
      ZStack(alignment: .topLeading) {
        flightMapView
        telemetryHUD
      }

      controlsPanel
    }
    .navigationTitle("Flight Path")
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      resetSimulation()
    }
    .task {
      // Ensure the polyline and model remain registered after any outgoing Map's onDisappear
      // calls RenderingCoordinator.shared.mapDidDisappear() during navigation transitions.
      try? await Task.sleep(for: .milliseconds(100))
      renderRevision &+= 1
      try? await Task.sleep(for: .milliseconds(350))
      renderRevision &+= 1
    }
    .onDisappear {
      isAnimating = false
    }
  }

  // MARK: - Map View

  private var flightMapView: some View {
    Map(camera: $camera, mode: .hybrid) {
      Polyline(
        path: visibleRoutePoints,
        altitudeMode: .absolute,
        zIndex: renderRevision
      )
      .stroke(
        .init(
          strokeColor: .cyan,
          strokeWidth: 5.0,
          outerColor: .white,
          outerWidth: 0.2
        )
      )
      .contour(
        .init(
          geodesic: true,
          extruded: false,
          drawOccludedSegments: true
        )
      )

      if showPlaneModel, let modelUrl = Self.airplaneModelUrl {
        Model(
          position: planePosition,
          url: modelUrl,
          altitudeMode: .absolute,
          zIndex: renderRevision,
          scale: .init(x: planeScale, y: planeScale, z: planeScale),
          orientation: .init(
            heading: planeHeading,
            tilt: 0.0,
            roll: 0.0
          )
        )
      }
    }
    .transaction { transaction in
      transaction.animation = nil
    }
    .background {
      TimelineView(.animation(paused: !isAnimating)) { context in
        Color.clear
          .onChange(of: context.date) { _, newDate in
            if isAnimating {
              updateSimulation(at: newDate)
            }
          }
      }
    }
  }

  private var telemetryHUD: some View {
    VStack(alignment: .leading, spacing: 2) {
      if playbackMode == .spline {
        Text(
          "Aircraft: \(planePosition.latitude, specifier: "%.4f"), \(planePosition.longitude, specifier: "%.4f")"
        )
        Text(
          "Altitude: \(planePosition.altitude, specifier: "%.0f") m (\(planePosition.altitude * 3.28084, specifier: "%.0f") ft MSL)"
        )
        Text(
          "Airspeed: \(currentAirspeedKnots, specifier: "%.0f") kts (\(currentAirspeedKnots * 1.852, specifier: "%.0f") km/h)"
        )
        Text(
          "Attitude: HDG \(planeHeading, specifier: "%.0f")° | PITCH \(planePitch, specifier: "%+.1f")° | ROLL \(planeRoll, specifier: "%+.1f")°"
        )
      } else {
        Text("Mode: SwiftUI KeyframeTrack (CubicKeyframe<Camera>)")
        Text("Waypoints: \(flightTimeline.steps.count) monotone cubic keyframes")
        Text(
          "Aircraft: \(planePosition.latitude, specifier: "%.4f"), \(planePosition.longitude, specifier: "%.4f") | \(planePosition.altitude, specifier: "%.0f") m"
        )
      }
      let pct = Int((currentDistance / flightTimeline.totalDistance) * 100)
      Text(
        "Distance: \(currentDistance / 1000.0, specifier: "%.1f") / \(flightTimeline.totalDistance / 1000.0, specifier: "%.1f") km (\(pct)%)"
      )
    }
    .font(.system(size: 9, weight: .bold, design: .monospaced))
    .foregroundColor(.primary)
    .padding(6)
    .background(.ultraThinMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 6))
    .padding(8)
  }

  private var controlsPanel: some View {
    VStack(spacing: 10) {
      Picker("Playback Mode", selection: $playbackMode) {
        ForEach(PlaybackMode.allCases) { mode in
          Text(mode.rawValue).tag(mode)
        }
      }
      .pickerStyle(.segmented)
      .onChange(of: playbackMode) { _, _ in
        resetSimulation()
      }

      Picker("Camera Perspective", selection: $cameraMode) {
        ForEach(FlightCameraMode.allCases) { mode in
          Text(mode.rawValue).tag(mode)
        }
      }
      .pickerStyle(.segmented)
      .onChange(of: cameraMode) { _, newMode in
        camera = FlightCameraRig.routeCamera(
          mode: newMode,
          position: planePosition,
          heading: planeHeading
        )
      }

      Toggle("Show 3D Aircraft Model", isOn: $showPlaneModel)
        .font(.caption.bold())
        .onChange(of: showPlaneModel) { _, _ in
          renderRevision &+= 1
        }

      HStack {
        Text("Speed: \(speedMultiplier, specifier: "%.0f")x")
          .font(.caption.monospacedDigit().bold())
          .frame(width: 110, alignment: .leading)
        Slider(value: $speedMultiplier, in: 1...20, step: 1)
      }

      if !hasStartedFlight {
        Button("Fly Along Route") {
          renderRevision &+= 1
          hasStartedFlight = true
          lastFrameDate = .now
          isAnimating = true
        }
        .buttonStyle(.borderedProminent)
      } else {
        HStack(spacing: 20) {
          Button(isAnimating ? "Pause" : "Resume") {
            if isAnimating {
              isAnimating = false
            } else {
              lastFrameDate = .now
              isAnimating = true
            }
          }
          .buttonStyle(.borderedProminent)

          Button("Reset") {
            resetSimulation()
          }
          .buttonStyle(.bordered)
        }
      }
    }
    .padding()
    .background(.ultraThinMaterial)
  }

  // MARK: - Simulation Helpers

  private func resetSimulation() {
    isAnimating = false
    hasStartedFlight = false
    currentDistance = 0.0
    activeSegmentIndex = 0
    lastFrameDate = nil

    visibleRoutePoints = flightTimeline.remainingPathPoints(forSegmentIndex: 0)
    renderRevision &+= 1

    let initialPos = flightTimeline.points.first ?? Self.startPosition
    let initialHeading = flightTimeline.steps.first?.bearing ?? Self.startHeading

    planePosition = initialPos
    planeHeading = initialHeading
    planePitch = 0.0
    planeRoll = 0.0
    currentAirspeedKnots = FlightTimeline.constantCruiseSpeedKnots

    camera = FlightCameraRig.routeCamera(
      mode: cameraMode,
      position: initialPos,
      heading: initialHeading
    )
  }

  private func updateSimulation(at currentDate: Date) {
    guard isAnimating else { return }

    let dt = currentDate.timeIntervalSince(lastFrameDate ?? currentDate)
    lastFrameDate = currentDate
    guard dt > 0 && dt < 0.25 else { return }

    let speedMps = FlightTimeline.constantCruiseSpeedKnots * FlightMath.metersPerSecondPerKnot
    let deltaDist = speedMps * dt * speedMultiplier
    let nextDistance = currentDistance + deltaDist

    if nextDistance >= flightTimeline.totalDistance {
      resetSimulation()
      return
    }

    currentDistance = nextDistance

    switch playbackMode {
    case .spline:
      let sample = flightTimeline.sample(
        atDistance: currentDistance,
        lookAheadMeters: 150.0,
        previousHeading: planeHeading,
        dt: dt
      )

      if sample.currentSegmentIndex != activeSegmentIndex {
        activeSegmentIndex = sample.currentSegmentIndex
        visibleRoutePoints = flightTimeline.remainingPathPoints(forSegmentIndex: activeSegmentIndex)
      }

      planePosition = sample.position
      planeHeading = sample.heading
      planePitch = sample.pitchDegrees
      planeRoll = sample.rollDegrees
      currentAirspeedKnots = sample.speedKnots

      camera = FlightCameraRig.routeCamera(
        mode: cameraMode,
        position: sample.position,
        heading: sample.heading
      )

    case .keyframe:
      let (evaluatedCamera, currentSeg) = flightTimeline.sampleKeyframeCamera(
        atDistance: currentDistance,
        mode: cameraMode
      )

      if currentSeg != activeSegmentIndex {
        activeSegmentIndex = currentSeg
        visibleRoutePoints = flightTimeline.remainingPathPoints(forSegmentIndex: activeSegmentIndex)
      }

      planePosition = evaluatedCamera.center
      planeHeading = evaluatedCamera.heading
      camera = evaluatedCamera
    }
  }
}

#Preview {
  FlyAlongRouteDemo()
}
