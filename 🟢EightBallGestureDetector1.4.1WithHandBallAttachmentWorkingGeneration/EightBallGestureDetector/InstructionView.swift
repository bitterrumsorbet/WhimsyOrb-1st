//
//  InstructionView.swift
//  EightBallGestureDetector
//
//  Created by Anran He on 22/05/2025.
//

import SwiftUI

struct InstructionView: View {
    //the Binding Bool that controls the appearance of the view
    //Got this button fucntion, showing and closing with the help from Kalia!
    @Binding var isShowing: Bool
    
    var body: some View {
        ZStack{
            Color.white.opacity(0.7)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                      isShowing = false
                    }
            // overlay background
            Color.yellow.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                      isShowing = false
                    }

            //instrcution panel
            VStack{
                Text("Flip you Right Hand plam UP to reveal the message")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .frame(width: 230)
                    .padding(.horizontal, 40)
                    .padding(.top, 40)
                
                Image("instructionFig")
                    .resizable()
                    .frame(width: 240, height: 200)
                    .padding(.horizontal,40)
                    
                
                Button(action: {
                    isShowing = false
                }) {
                    Text("Got it!")
                }
                .font(.title3.bold())
                .padding(.top, 30)
                .padding(.bottom, 40)
                
            }
            //i used the padding for each element to adjust the size of the window background
            .glassBackgroundEffect()
            
        }
    }
}

struct InstructionView_Previews: PreviewProvider {
  @State static var isShowing = true
  static var previews: some View {
    InstructionView(isShowing: $isShowing)
  }
}

