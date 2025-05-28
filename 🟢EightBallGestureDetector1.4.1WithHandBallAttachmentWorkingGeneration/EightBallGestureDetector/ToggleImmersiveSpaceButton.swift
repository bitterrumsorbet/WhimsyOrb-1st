//
//  ToggleImmersiveSpaceButton.swift
//  EightBallGestureDetector
//
//  Created by Anran He on 23/04/2025.
//

import SwiftUI

struct ToggleImmersiveSpaceButton: View {

    @Environment(AppModel.self) private var appModel

    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace

    var body: some View {
        Button {
            Task { @MainActor in
                switch appModel.immersiveSpaceState {
                    case .open:
                        appModel.immersiveSpaceState = .inTransition
                        await dismissImmersiveSpace()
                        // Don't set immersiveSpaceState to .closed because there
                        // are multiple paths to ImmersiveView.onDisappear().
                        // Only set .closed in ImmersiveView.onDisappear().

                    case .closed:
                        appModel.immersiveSpaceState = .inTransition
                        switch await openImmersiveSpace(id: appModel.immersiveSpaceID) {
                            case .opened:
                                // Don't set immersiveSpaceState to .open because there
                                // may be multiple paths to ImmersiveView.onAppear().
                                // Only set .open in ImmersiveView.onAppear().
                                break

                            case .userCancelled, .error:
                                // On error, we need to mark the immersive space
                                // as closed because it failed to open.
                                fallthrough
                            @unknown default:
                                // On unknown response, assume space did not open.
                                appModel.immersiveSpaceState = .closed
                        }

                    case .inTransition:
                        // This case should not ever happen because button is disabled for this case.
                        break
                }
            }
        } label: {
            Text(appModel.immersiveSpaceState == .open ? "I'm done, byeeee" : "Summon the Orb!")
        }
        .disabled(appModel.immersiveSpaceState == .inTransition)
        //got the button style tutorial from Coco
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .animation(.interactiveSpring, value: 0)
        .fontWeight(.heavy)
        .font(.system(size: 30, weight: .heavy, design: .default))
        .shadow(radius: 3)
        .background(Color.orange.cornerRadius(20))
        .frame(width: 500, height: 100)
        
    }
}
#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
