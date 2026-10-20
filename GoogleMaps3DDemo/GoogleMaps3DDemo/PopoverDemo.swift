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

public struct PopoverDemo: View {
  @State private var isCoordinateWindowOpen: Bool = false
  @State private var isFerryBuildingMarkerPopoverOpen: Bool = false
  @State private var autoCloseEnabled: Bool = false
  @State private var autoPanEnabled: Bool = true

  private let ferryBuildingMarker = Marker3D(position: .ferryBuilding)

  public var body: some View {
    ZStack(alignment: .bottom) {
      Map(initialCamera: .sanFrancisco, mode: .satellite) {
        Popover(
          positionAnchor: .alcatrazIsland,
          altitudeMode: .relativeToGround,
          isOpen: $isCoordinateWindowOpen,
          offset: CGSize(width: 0, height: -10),
          autoClosedEnabled: autoCloseEnabled,
          autoPanEnabled: autoPanEnabled
        ) {
          VStack {
            Text("Alcatraz Island").font(.headline)
            Text("Anchored to a coordinate.")
          }
        }
        .style(
          PopoverStyle(
            padding: 20,
            backgroundColor: .blue,
            borderRadius: 8,
            shadow: Shadow(color: .blue.opacity(1), radius: 50, x: 0, y: 2)
          )
        )

        ferryBuildingMarker
          .popover(
            isOpen: $isFerryBuildingMarkerPopoverOpen,
            autoClosedEnabled: autoCloseEnabled,
            autoPanEnabled: autoPanEnabled,
            style: PopoverStyle(
              padding: 20,
              backgroundColor: .red,
              borderRadius: 8
            )
          ) {
            VStack {
              Text("Ferry Building").font(.headline)
              Text("Anchored to a marker.")
            }
          }
          .onTap {
            isFerryBuildingMarkerPopoverOpen.toggle()
          }
      }

      VStack(spacing: 8) {
        Toggle("Show Coordinate Popover (Alcatraz)", isOn: $isCoordinateWindowOpen)
        Toggle("Show Marker Popover (Ferry Building)", isOn: $isFerryBuildingMarkerPopoverOpen)
        Divider()
        Toggle("Auto-Close on Map Tap", isOn: $autoCloseEnabled)
        Toggle("Auto-Pan Camera to Popover", isOn: $autoPanEnabled)
      }
      .font(.subheadline)
      .padding()
      .background(.ultraThinMaterial)
      .clipShape(RoundedRectangle(cornerRadius: 10))
      .padding()
    }
    .navigationTitle("Popover Demo")
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  PopoverDemo()
}
