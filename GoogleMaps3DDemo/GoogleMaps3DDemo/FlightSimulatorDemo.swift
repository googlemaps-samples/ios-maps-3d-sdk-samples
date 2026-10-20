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

struct FlightSimulatorDemo: View {
  @State private var session = FlightSession()
  @State private var showInstructions: Bool = true

  var body: some View {
    @Bindable var bindableSession = session

    ZStack {
      // 1. 60Hz 3D Simulation Loop (First-Person Cockpit / FPV View)
      TimelineView(.animation(paused: !session.isFlying)) { context in
        Map(camera: $bindableSession.camera, mode: .hybrid)
          .onChange(of: context.date) { _, newDate in
            session.tick(at: newDate)
          }
      }
      .ignoresSafeArea()

      // 2. Flight Simulator HUD & Avionics Overlay
      VStack(spacing: 0) {
        topAvionicsTape
          .padding(.top, 8)

        Spacer()

        cockpitCrosshair

        if !session.countdownText.isEmpty {
          countdownOverlay
        }

        Spacer()

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
      session.prepareSensors()
      session.resetToPreset(session.selectedPreset)
    }
    .onDisappear {
      session.stop()
    }
  }

  // MARK: - UI Avionics Components

  private var topAvionicsTape: some View {
    let pitch = session.currentPitch
    let roll = session.currentRoll
    let state = session.aircraftState

    return HStack {
      VStack(alignment: .leading, spacing: 1) {
        Text("AIRSPEED")
          .font(.system(size: 8, weight: .bold, design: .monospaced))
          .foregroundColor(.secondary)
        Text("\(session.airspeedKnots, specifier: "%.0f") KTS")
          .font(.system(size: 11, weight: .bold, design: .monospaced))
          .foregroundColor(.primary)
      }
      .padding(6)
      .background(.ultraThinMaterial)
      .clipShape(RoundedRectangle(cornerRadius: 6))

      Spacer()

      VStack(spacing: 1) {
        Text("HDG \(state.heading, specifier: "%03.0f")°")
          .font(.system(size: 11, weight: .heavy, design: .monospaced))
          .foregroundColor(.primary)
        HStack(spacing: 6) {
          Text(pitch >= 0 ? "PITCH: +\(Int(pitch))° (CLIMB)" : "PITCH: \(Int(pitch))° (DIVE)")
            .foregroundColor(pitch >= 2 ? .green : (pitch <= -2 ? .orange : .secondary))
          Text("BANK: \(roll, specifier: "%+.0f")°")
        }
        .font(.system(size: 8, weight: .semibold, design: .monospaced))
      }
      .padding(6)
      .background(.ultraThinMaterial)
      .clipShape(RoundedRectangle(cornerRadius: 6))

      Spacer()

      VStack(alignment: .trailing, spacing: 1) {
        Text("ALT (MSL)")
          .font(.system(size: 8, weight: .bold, design: .monospaced))
          .foregroundColor(.secondary)
        Text("\(state.position.altitude, specifier: "%.0f") M")
          .font(.system(size: 11, weight: .bold, design: .monospaced))
          .foregroundColor(
            state.position.altitude <= session.selectedPreset.minFloorAltitude + 50
              ? .yellow : .primary
          )
        Text(
          state.verticalSpeedMps >= 0
            ? "VSI: +\(Int(state.verticalSpeedMps)) m/s"
            : "VSI: \(Int(state.verticalSpeedMps)) m/s"
        )
        .font(.system(size: 7, weight: .bold, design: .monospaced))
        .foregroundColor(
          state.verticalSpeedMps >= 1
            ? .green : (state.verticalSpeedMps <= -1 ? .orange : .secondary)
        )
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
    Text(session.countdownText)
      .font(.system(size: 64, weight: .heavy, design: .rounded))
      .foregroundColor(.white)
      .shadow(color: .black.opacity(0.8), radius: 10, x: 0, y: 4)
      .scaleEffect(session.countdownValue == 0 ? 1.3 : 1.0)
      .animation(.spring(response: 0.3, dampingFraction: 0.6), value: session.countdownValue)
  }

  private var bottomControlsConsole: some View {
    @Bindable var bindableSession = session

    return VStack(spacing: 8) {
      if !session.isMotionAvailable {
        HStack(spacing: 16) {
          VStack(alignment: .leading, spacing: 2) {
            Text("Pitch: \(session.manualPitch, specifier: "%.0f")° (Pull up / Push down)")
              .font(.system(size: 9, weight: .bold, design: .monospaced))
            Slider(value: $bindableSession.manualPitch, in: -35...35, step: 1)
          }
          VStack(alignment: .leading, spacing: 2) {
            Text("Bank: \(session.manualRoll, specifier: "%.0f")° (Left / Right turn)")
              .font(.system(size: 9, weight: .bold, design: .monospaced))
            Slider(value: $bindableSession.manualRoll, in: -45...45, step: 1)
          }
        }
      }

      // Responsive layout: single row in landscape, stacked rows in portrait
      ViewThatFits(in: .horizontal) {
        HStack(spacing: 12) {
          presetPicker
          throttleControl
          actionButtons
        }

        VStack(spacing: 8) {
          HStack(spacing: 12) {
            presetPicker
            throttleControl
          }
          HStack(spacing: 12) {
            actionButtons
          }
        }
      }
    }
    .padding(10)
    .background(.ultraThinMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 10))
  }

  private var presetPicker: some View {
    @Bindable var bindableSession = session

    return Picker("Location", selection: $bindableSession.selectedPreset) {
      ForEach(FlightLocationPreset.allCases) { preset in
        Text(preset.rawValue).tag(preset)
      }
    }
    .pickerStyle(.menu)
    .fixedSize()
    .onChange(of: session.selectedPreset) { _, newPreset in
      session.resetToPreset(newPreset)
    }
  }

  private var throttleControl: some View {
    @Bindable var bindableSession = session

    return HStack(spacing: 6) {
      Text("Throttle")
        .font(.system(size: 9, weight: .bold, design: .monospaced))
      Slider(value: $bindableSession.airspeedKnots, in: 80...260, step: 10)
        .frame(minWidth: 100)
    }
  }

  @ViewBuilder
  private var actionButtons: some View {
    if session.isMotionAvailable && session.isFlying {
      Button("Calibrate Level") {
        session.calibrateLevel()
      }
      .font(.system(size: 11, weight: .semibold))
      .buttonStyle(.bordered)
    }

    Button(session.isFlying ? "Pause" : "Start Flight") {
      if session.isFlying {
        session.pauseFlight()
      } else {
        session.startFlightWithCountdown()
      }
    }
    .font(.system(size: 11, weight: .semibold))
    .buttonStyle(.borderedProminent)
    .disabled(session.countdownValue > 0)

    Button("Reset") {
      session.resetToPreset(session.selectedPreset)
    }
    .font(.system(size: 11, weight: .semibold))
    .buttonStyle(.bordered)
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
              Text("Hold in Landscape or Portrait Mode")
                .font(.subheadline.bold())
              Text("Hold your device comfortably; gravity-based sensors adapt to your screen orientation.")
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
              Text("Pull back towards you to pitch up and climb. Push forward away from you to pitch down and descend.")
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
              Text("Altitude Envelope (MSL)")
                .font(.subheadline.bold())
              Text("Each preset configures a regional Mean Sea Level (MSL) minimum and maximum altitude band.")
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
