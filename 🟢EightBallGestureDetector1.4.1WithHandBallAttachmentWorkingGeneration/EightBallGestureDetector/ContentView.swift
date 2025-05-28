//
//  ContentView.swift
//  EightBallGestureDetector
//
//  Created by Anran He on 23/04/2025.
//

import SwiftUI
import RealityKit
import RealityKitContent


struct ContentView: View {
    @Environment(AppModel.self) private var appModel
    
    //the boolean value for showing instruction view
    @State private var showIntro = false
    
    //tutorial from apple documentation:https://developer.apple.com/documentation/swiftui/adding-a-background-to-your-view
    //shared with Kalia, Elsa and Coco
    //adding a gradient value to the background
    let backgroundGradient = LinearGradient(
        colors: [Color.purple, Color.orange, Color.purple],
        startPoint: .top, endPoint: .bottom
        
    )
    
    var body: some View {
        ZStack {
            //creating the background gradient
            backgroundGradient
            //main content
            VStack {
                Text("WhimsyOrb")
                    .font(.system(size: 90))
                    .fontWeight(.heavy)
                    .padding()
                
                Text("Your Sassy Spatial Fortune Teller/Guardian Angel")
                    .font(.system(size: 30))
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Image("winkyIntro")
                    .resizable()
                    .frame(width: 250, height: 250)
                    .padding()
                    .shadow(radius: 5)
            
                //Adding a button to call InstructionView
                Button("How to play?"){
                    showIntro = true
                }
                .buttonStyle(.borderedProminent)
                .fontWeight(.bold)
                .shadow(radius: 3)
                .padding(.vertical, 1)
                
                ToggleImmersiveSpaceButton()
                    
            }
            .padding()
            if showIntro {
                InstructionView(isShowing: $showIntro)
            }
        }
        //extend the gradient colors to infinity!
        .ignoresSafeArea()
    }
        
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
