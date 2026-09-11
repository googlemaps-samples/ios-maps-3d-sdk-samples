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

/// Preset scenic locations featuring spectacular 3D topography and urban structures.
enum FlightLocationPreset: String, CaseIterable, Identifiable {
  case grandCanyon = "Grand Canyon"
  case sanFrancisco = "San Francisco"
  case alpsInnsbruck = "Innsbruck Alps"
  case newYork = "New York City"

  var id: String { rawValue }

  // Initial flight location in Mean Sea Level (MSL) altitude
  var initialLocation: LatLngAltitude {
    switch self {
    case .grandCanyon:
      return LatLngAltitude(latitude: 36.0946, longitude: -111.8435, altitude: 2400.0)
    case .sanFrancisco:
      return LatLngAltitude(latitude: 37.7958, longitude: -122.3950, altitude: 450.0)
    case .alpsInnsbruck:
      return LatLngAltitude(latitude: 47.2630, longitude: 11.3704, altitude: 1800.0)
    case .newYork:
      return LatLngAltitude(latitude: 40.7050, longitude: -74.0090, altitude: 450.0)
    }
  }

  var initialHeading: Double {
    switch self {
    case .grandCanyon: return 185.0
    case .sanFrancisco: return 288.0
    case .alpsInnsbruck: return 240.0
    case .newYork: return 30.0
    }
  }

  var minFloorAltitude: Double {
    switch self {
    case .grandCanyon: return 1100.0
    case .sanFrancisco: return 120.0
    case .alpsInnsbruck: return 850.0
    case .newYork: return 150.0
    }
  }

  var maxCeilingAltitude: Double {
    switch self {
    case .grandCanyon: return 6000.0
    case .sanFrancisco: return 3500.0
    case .alpsInnsbruck: return 6000.0
    case .newYork: return 3500.0
    }
  }
}

struct FlightSimulatorDemo: View {
  @StateObject private var motionManager = FlightMotionManager()

  // Flight simulation state
  @State private var selectedPreset: FlightLocationPreset = .grandCanyon
  @State private var airspeedKnots: Double = 140.0
  @State private var isFlying: Bool = false

  // Startup guidance & countdown
  @State private var showInstructions: Bool = true
  @State private var countdownValue: Int = 0
  @State private var countdownText: String = ""

  // Current aircraft 3D position, heading, and vertical speed (MSL)
  @State private var aircraftPos: LatLngAltitude = FlightLocationPreset.grandCanyon.initialLocation
  @State private var aircraftHeading: Double = FlightLocationPreset.grandCanyon.initialHeading
  @State private var verticalSpeedMps: Double = 0.0

  // Manual fallback controls for Xcode Simulator testing
  @State private var manualPitch: Double = 0.0
  @State private var manualRoll: Double = 0.0

  // Delta time tracking
  @State private var lastFrameDate: Date? = nil

  // First-Person Cockpit / Drone Camera (bounded tilt for optimal 3D tile memory management)
  @State private var camera: Camera = .init(
    center: FlightLocationPreset.grandCanyon.initialLocation,
    heading: FlightLocationPreset.grandCanyon.initialHeading,
    tilt: 75.0,
    roll: 0.0,
    range: 50.0,
    altitudeMode: .absolute
  )

  var body: some View {
    ZStack {
      // 1. 60Hz 3D Simulation Loop (Pure First-Person Cockpit / FPV Drone View)
      TimelineView(.animation(paused: !isFlying)) { context in
        Map(camera: $camera, mode: .hybrid)
          .onChange(of: context.date) { _, newDate in
            if isFlying {
              updateFlightPhysics(at: newDate)
            }
          }
      }
      .ignoresSafeArea()

      // 2. Flight Simulator HUD & Avionics Overlay
      VStack(spacing: 0) {
        // Top Compass Heading, Pitch, Bank, and Vertical Speed
        topAvionicsTape
          .padding(.top, 8)

        Spacer()

        // Center Cockpit Flight Reticle / Crosshair
        cockpitCrosshair

        // Center Countdown Display
        if countdownValue > 0 {
          countdownOverlay
        }

        Spacer()

        // Bottom Controls Console
        bottomControlsConsole
      }
      .padding(.horizontal, 12)
      .padding(.bottom, 8)
    }
    .navigationTitle("Flight Simulator")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          showInstructions = true
        } label: {
          Image(systemName: "questionmark.circle")
        }
      }
    }
    .sheet(isPresented: $showInstructions) {
      flightInstructionsSheet
    }
    .onAppear {
      resetToPreset(selectedPreset)
      motionManager.startMotionUpdates()
    }
    .onDisappear {
      motionManager.stopMotionUpdates()
    }
  }

  // MARK: - Flight Physics Integration Loop

  private var currentPitch: Double {
    motionManager.isMotionAvailable ? motionManager.filteredPitch : manualPitch
  }

  private var currentRoll: Double {
    motionManager.isMotionAvailable ? motionManager.filteredRoll : manualRoll
  }

  private func updateFlightPhysics(at currentDate: Date) {
    let dt = currentDate.timeIntervalSince(lastFrameDate ?? currentDate)
    lastFrameDate = currentDate

    guard dt > 0 && dt < 0.25 else { return }

    // 1. Coordinated Turn Rate from Bank Angle: yawRate = bankAngle * 0.75 deg/sec
    let yawRate = currentRoll * 0.75
    aircraftHeading = (aircraftHeading + yawRate * dt).truncatingRemainder(dividingBy: 360.0)
    if aircraftHeading < 0 { aircraftHeading += 360.0 }

    // 2. Airspeed (knots to meters per second)
    let speedMps = airspeedKnots * 0.514444

    // 3. Vertical Speed (climb when pitch > 0, dive when pitch < 0)
    let climbAngleRad = currentPitch * (.pi / 180.0)
    verticalSpeedMps = speedMps * sin(climbAngleRad)

    // 4. Terrain Floor & Ceiling Clamping (MSL)
    let rawAlt = aircraftPos.altitude + verticalSpeedMps * dt
    let clampedAlt = max(selectedPreset.minFloorAltitude, min(selectedPreset.maxCeilingAltitude, rawAlt))

    // 5. Horizontal Distance Traveled
    let horizontalSpeedMps = speedMps * cos(climbAngleRad)
    let distanceMeters = horizontalSpeedMps * dt

    // 6. Spherical Coordinate Integration (Haversine forward projection)
    let newCoordinate = projectCoordinate(
      from: aircraftPos,
      bearingDegrees: aircraftHeading,
      distanceMeters: distanceMeters
    )

    aircraftPos = LatLngAltitude(
      latitude: newCoordinate.latitude,
      longitude: newCoordinate.longitude,
      altitude: clampedAlt
    )

    // 7. First-Person Cockpit Camera Follow Synchronization
    // Tilt is clamped to [50°, 80°] to bound the 3D tile frustum depth and prevent tile streaming memory growth on 4GB devices
    let boundedTilt = max(50.0, min(80.0, 75.0 + currentPitch * 0.3))

    camera = Camera(
      center: aircraftPos,
      heading: aircraftHeading,
      tilt: boundedTilt,
      roll: -currentRoll * 0.35,
      range: 50.0,
      altitudeMode: .absolute
    )
  }

  /// Projects a starting coordinate along a bearing and distance over Earth's spherical surface.
  private func projectCoordinate(
    from origin: LatLngAltitude,
    bearingDegrees: Double,
    distanceMeters: Double
  ) -> CLLocationCoordinate2D {
    let rEarth = 6371000.0 // Mean Earth radius in meters
    let dOverR = distanceMeters / rEarth

    let lat1 = origin.latitude * .pi / 180.0
    let lon1 = origin.longitude * .pi / 180.0
    let brg = bearingDegrees * .pi / 180.0

    let lat2 = asin(sin(lat1) * cos(dOverR) + cos(lat1) * sin(dOverR) * cos(brg))
    let lon2 = lon1 + atan2(sin(brg) * sin(dOverR) * cos(lat1), cos(dOverR) - sin(lat1) * sin(lat2))

    return CLLocationCoordinate2D(
      latitude: lat2 * 180.0 / .pi,
      longitude: lon2 * 180.0 / .pi
    )
  }

  private func startFlightWithCountdown() {
    // 1. Calibrate zero level to current handheld grip angle
    motionManager.calibrateZeroLevel()

    // 2. Run animated 3-2-1 countdown
    isFlying = false
    countdownValue = 3
    countdownText = "3"

    Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
      DispatchQueue.main.async {
        self.countdownValue -= 1
        if self.countdownValue == 2 {
          self.countdownText = "2"
        } else if self.countdownValue == 1 {
          self.countdownText = "1"
        } else if self.countdownValue == 0 {
          self.countdownText = "FLY!"
          self.lastFrameDate = Date()
          self.isFlying = true
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.countdownText = ""
          }
          timer.invalidate()
        }
      }
    }
  }

  private func resetToPreset(_ preset: FlightLocationPreset) {
    isFlying = false
    aircraftPos = preset.initialLocation
    aircraftHeading = preset.initialHeading
    verticalSpeedMps = 0.0
    lastFrameDate = nil

    camera = Camera(
      center: preset.initialLocation,
      heading: preset.initialHeading,
      tilt: 75.0,
      roll: 0.0,
      range: 50.0,
      altitudeMode: .absolute
    )
  }

  // MARK: - UI Avionics Components

  private var topAvionicsTape: some View {
    HStack {
      // Speed readout
      VStack(alignment: .leading, spacing: 1) {
        Text("AIRSPEED")
          .font(.system(size: 8, weight: .bold, design: .monospaced))
          .foregroundColor(.secondary)
        Text("\(airspeedKnots, specifier: "%.0f") KTS")
          .font(.system(size: 11, weight: .bold, design: .monospaced))
          .foregroundColor(.primary)
      }
      .padding(6)
      .background(.ultraThinMaterial)
      .clipShape(RoundedRectangle(cornerRadius: 6))

      Spacer()

      // Heading, Pitch, and Bank Status
      VStack(spacing: 1) {
        Text("HDG \(aircraftHeading, specifier: "%03.0f")°")
          .font(.system(size: 11, weight: .heavy, design: .monospaced))
          .foregroundColor(.primary)
        HStack(spacing: 6) {
          Text(currentPitch >= 0 ? "PITCH: +\(Int(currentPitch))° (CLIMB)" : "PITCH: \(Int(currentPitch))° (DIVE)")
            .foregroundColor(currentPitch >= 2 ? .green : (currentPitch <= -2 ? .orange : .secondary))
          Text("BANK: \(currentRoll, specifier: "%+.0f")°")
        }
        .font(.system(size: 8, weight: .semibold, design: .monospaced))
      }
      .padding(6)
      .background(.ultraThinMaterial)
      .clipShape(RoundedRectangle(cornerRadius: 6))

      Spacer()

      // Altitude (MSL) and Vertical Speed Indicator (VSI)
      VStack(alignment: .trailing, spacing: 1) {
        Text("ALT (MSL)")
          .font(.system(size: 8, weight: .bold, design: .monospaced))
          .foregroundColor(.secondary)
        Text("\(aircraftPos.altitude, specifier: "%.0f") M")
          .font(.system(size: 11, weight: .bold, design: .monospaced))
          .foregroundColor(aircraftPos.altitude <= selectedPreset.minFloorAltitude + 50 ? .yellow : .primary)
        Text(verticalSpeedMps >= 0 ? "VSI: +\(Int(verticalSpeedMps)) m/s" : "VSI: \(Int(verticalSpeedMps)) m/s")
          .font(.system(size: 7, weight: .bold, design: .monospaced))
          .foregroundColor(verticalSpeedMps >= 1 ? .green : (verticalSpeedMps <= -1 ? .orange : .secondary))
      }
      .padding(6)
      .background(.ultraThinMaterial)
      .clipShape(RoundedRectangle(cornerRadius: 6))
    }
  }

  private var cockpitCrosshair: some View {
    ZStack {
      Circle()
        .stroke(.white.opacity(0.6), lineWidth: 1.5)
        .frame(width: 36, height: 36)
      Rectangle()
        .fill(.white.opacity(0.6))
        .frame(width: 50, height: 1)
      Rectangle()
        .fill(.white.opacity(0.6))
        .frame(width: 1, height: 50)
    }
  }

  private var countdownOverlay: some View {
    Text(countdownText)
      .font(.system(size: 64, weight: .heavy, design: .rounded))
      .foregroundColor(.white)
      .shadow(color: .black.opacity(0.8), radius: 10, x: 0, y: 4)
      .scaleEffect(countdownValue == 0 ? 1.3 : 1.0)
      .animation(.spring(response: 0.3, dampingFraction: 0.6), value: countdownValue)
  }

  private var bottomControlsConsole: some View {
    VStack(spacing: 8) {
      // Manual controls for Xcode Simulator testing
      if !motionManager.isMotionAvailable {
        HStack(spacing: 16) {
          VStack(alignment: .leading, spacing: 2) {
            Text("Pitch: \(manualPitch, specifier: "%.0f")° (Pull up / Push down)")
              .font(.system(size: 9, weight: .bold, design: .monospaced))
            Slider(value: $manualPitch, in: -35...35, step: 1)
          }
          VStack(alignment: .leading, spacing: 2) {
            Text("Bank: \(manualRoll, specifier: "%.0f")° (Left / Right turn)")
              .font(.system(size: 9, weight: .bold, design: .monospaced))
            Slider(value: $manualRoll, in: -45...45, step: 1)
          }
        }
      }

      // Location Picker and Flight Actions
      HStack(spacing: 12) {
        Picker("Location", selection: $selectedPreset) {
          ForEach(FlightLocationPreset.allCases) { preset in
            Text(preset.rawValue).tag(preset)
          }
        }
        .pickerStyle(.menu)
        .onChange(of: selectedPreset) { _, newPreset in
          resetToPreset(newPreset)
        }

        HStack(spacing: 6) {
          Text("Throttle")
            .font(.system(size: 9, weight: .bold, design: .monospaced))
          Slider(value: $airspeedKnots, in: 80...260, step: 10)
        }

        if motionManager.isMotionAvailable && isFlying {
          Button("Calibrate Level") {
            motionManager.calibrateZeroLevel()
          }
          .font(.system(size: 11, weight: .semibold))
          .buttonStyle(.bordered)
        }

        Button(isFlying ? "Pause" : "Start Flight") {
          if isFlying {
            isFlying = false
          } else {
            startFlightWithCountdown()
          }
        }
        .font(.system(size: 11, weight: .semibold))
        .buttonStyle(.borderedProminent)

        Button("Reset") {
          resetToPreset(selectedPreset)
        }
        .font(.system(size: 11, weight: .semibold))
        .buttonStyle(.bordered)
      }
    }
    .padding(10)
    .background(.ultraThinMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 10))
  }

  // MARK: - Flight Instructions Sheet

  private var flightInstructionsSheet: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 18) {
        Text("How to Pilot the 3D Flight Simulator")
          .font(.headline)

        VStack(alignment: .leading, spacing: 12) {
          HStack(alignment: .top, spacing: 12) {
            Image(systemName: "iphone.landscape")
              .font(.title2)
              .foregroundColor(.blue)
              .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
              Text("Hold in Landscape Mode")
                .font(.subheadline.bold())
              Text("Hold your device with both hands like a flight yoke.")
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }

          HStack(alignment: .top, spacing: 12) {
            Image(systemName: "arrow.up.and.down")
              .font(.title2)
              .foregroundColor(.green)
              .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
              Text("Tilt Forward / Backward to Pitch & Climb")
                .font(.subheadline.bold())
              Text("Pull back towards you to pitch up and climb into the sky. Push forward away from you to pitch down and dive.")
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }

          HStack(alignment: .top, spacing: 12) {
            Image(systemName: "arrow.turn.up.right")
              .font(.title2)
              .foregroundColor(.orange)
              .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
              Text("Tilt Left / Right to Bank & Turn")
                .font(.subheadline.bold())
              Text("Tilt your right hand down to bank right and turn right. Tilt left hand down to turn left.")
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }

          HStack(alignment: .top, spacing: 12) {
            Image(systemName: "gauge.with.needle")
              .font(.title2)
              .foregroundColor(.purple)
              .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
              Text("Calibrated Terrain Floor & Ceiling Limits")
                .font(.subheadline.bold())
              Text("The simulator enforces safety floor and ceiling envelopes for each region, preventing the aircraft from clipping underground.")
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }

          HStack(alignment: .top, spacing: 12) {
            Image(systemName: "scope")
              .font(.title2)
              .foregroundColor(.red)
              .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
              Text("What is 'Calibrate Level'?")
                .font(.subheadline.bold())
              Text("Zeroes out the motion sensors at your current handheld angle so you can fly comfortably at any resting posture.")
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }
        }

        Spacer()

        Button("Got It — Ready to Fly") {
          showInstructions = false
        }
        .frame(maxWidth: .infinity)
        .buttonStyle(.borderedProminent)
      }
      .padding()
      .navigationTitle("Flight Briefing")
      .navigationBarTitleDisplayMode(.inline)
    }
    .presentationDetents([.medium, .large])
  }
}

#Preview {
  FlightSimulatorDemo()
}
