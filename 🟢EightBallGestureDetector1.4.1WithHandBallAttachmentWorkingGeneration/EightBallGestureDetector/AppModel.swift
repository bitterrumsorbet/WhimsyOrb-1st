//
//  AppModel.swift
//  EightBallGestureDetector
//
//  Created by Anran He on 23/04/2025.
//

import SwiftUI
import RealityKit


/// Maintains app-wide state, it holds most of the defined elements in the app
@MainActor
@Observable
class AppModel {
    let immersiveSpaceID = "ImmersiveSpace"
    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }
    var immersiveSpaceState = ImmersiveSpaceState.closed
    
    //for palm detection
    var latestRightHandThumbTip = simd_float3(repeating: 0.0)
    var latestRightHandMiddleFingerTip = simd_float3(repeating: 0.0)
    var latestRightHandForearmWrist = simd_float3(repeating: 0.0)
    
    // State tracking for palm orientation
    var lastPalmState = false
    var isPalmUp = false
    var palmStateChangeTime: Date?
    
    // Eight ball gesture state
    var isEightBallGestureDetected = false
    var lastEightBallGestureTime: Date?
    
    // Combined state for showing messages, shouldShowMessage is achieved when both the gesture is detected , and when the palm is facing up
    var shouldShowMessage = false
    var currentMessage = ""
    //A boolean that stablisies the message after it's been generated, set into false first because initially the message haven't shown
    var haveShownMessage = false
    
    //create a list of messages to be displayed randomly
    let messages = [
        "An island full of cute penguins awaits you soon",
        "Trust your instincts on what to choose for lunch",
        "May the situationships ship away from you",
        "Life is like a software update, takes forever, but eventually everything runs smoother",
        "Oysters don’t rush, and neither should you",
        "Life’s a meme - make it good and weird",
        "Confidence is just enthusiasm with sunglasses",
        "Get some ej3ieoo9feee% get some (shhh I'm pretending to glitch)",
        "Are people who don't serve you still bothering you? Not any more! Be gone trolls!!!",
        "That gym membership is working more than you think it is...",
        "A period of binging your favorite TV is necessary",
        "You👏Are👏So👏Loved👏",
        "This is just a friendly reminder to drink some water!",
        "If life gives you lemonade, make lemons - Phil Dunphy(Modern Family, 2009)",
        "Buh...what was I about to say? Sorry brain fart, just be you-self!",
        "You got this you BAD B*TCH!",
        "Your kindness to others will return tenfold because you're amaaaaazing",
        "Hey, I am always here for you, okay? <333 ",
        "Follow the Yellow Brick road.",
        "You're not weird, you are a limited edition",
        "Well, you have to choose, life ain't the first few episodes of Love Island.",
        "I think a cup of pumpkin spice latte will fix it.",
        "I think a cup of hot chocolate will fix it",
        "I think a cup of hot tea will fix it",
        "I think a sweet treat will fix it",
        "You're the sunshine when it rains.",
        "Sure",
        "Go ahead",
        "Nope",
        "Nopedy nope nope",
        "Bahhh...maybe?",
        "YASSSSSSS",
        "Might need to rethink.",
        "Outlook: You'll SLAY!"
    ]
    
    
    //create a function to get random messages
    func getRandomMessage() -> String {
        messages.randomElement() ?? "Heya, what do you got for me today???"
    }
    
    // Refresh the current message
    func refreshMessage() {
        currentMessage = getRandomMessage()
           
    }
    
}
