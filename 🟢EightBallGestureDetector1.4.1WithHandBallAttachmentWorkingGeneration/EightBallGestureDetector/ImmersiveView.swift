//
//  ImmersiveView.swift
//  EightBallGestureDetector
//
//  Created by Anran He on 23/04/2025.
//

import SwiftUI
import RealityKit
import RealityKitContent
import ARKit
//HandVector library from: https://github.com/XanderXu/HandVector
import HandVector

struct ImmersiveView: View {
    @Environment(AppModel.self) private var appModel
    
    @State var jointPositions: [HandSkeleton.JointName: SIMD3<Float>] = [:]
    
    //NEW: variable that monitors the gesture and palm orientation
    @State private var showingMessageView = false
    
    // Gesture detection parameters
    var latestHandTracking: HandVectorManager = .init(left: nil, right: nil)
    let eightBallHandInfo = String.eightBallPosition.toModel(HVHandJsonModel.self)!.convertToHVHandInfo()
    let thresholdForEightBallDetection: Float = 0.9
    
    //NEW: Cooldown timer to prevent rapid message changes
    @State private var lastMessageTime: Date? = nil
    let messageCooldownSeconds: TimeInterval = 3.0
    
    // via: https://stepinto.vision/labs/lab-007-anchor-an-attachment-to-a-hand/
    // Set up a tracked entity with an anchor
    // RealityKit will update this in real time
    // No need for ARKit or hand tracking
    //Shared this hand Attachment code with Qing!
    @State var handTrackedEntity: Entity = {
        let handAnchor = AnchorEntity(.hand(.right, location: .aboveHand))
        return handAnchor
    }()
    
    // ? because it's optional - it could be nil!
    @State var theMessageViewAttachmentEntity:ViewAttachmentEntity?
    
    
    var body: some View {
        
        ZStack{
            RealityView { content, attachments  in
                
                //adding ambient audio, tutorial from https://github.com/calebwinningham/VisionOS_TutorialExamples/tree/main/VisionOS_AmbientAudio
                //current music from Joe Hisaishi https://open.spotify.com/track/3XxnYdibSlBhiq2wGlQ6ie
                //shared this section with Coco
                guard let AudioEntity = try? await Entity(named: "AudioController", in: realityKitContentBundle) else {
                    fatalError("Unable to load audio model.")
                }
                let ambientAudioEnitityController = AudioEntity.findEntity(named: "AmbientAudio")
                let audioFileName = "/Root/ThePathOfTheWind_mp3"
                guard let resource = try? await AudioFileResource(named: audioFileName, from: "AudioController.usda", in: realityKitContentBundle) else {fatalError("Unable to load audio resource.")}
                let audioController = ambientAudioEnitityController?.prepareAudio(resource)
                audioController?.play()
                content.add(AudioEntity)
                
                // add the handtracked entity to the root of the RealityView Scene graph
                content.add(handTrackedEntity)
                
                // if the attachment entity exists, let it be the child oif the hand tracked entity
                if let attachmentEntity = attachments.entity(for: "RandomMessageView") {
                    
                    //make the view always face the user
                    attachmentEntity.components[BillboardComponent.self] = .init()
                    
                    //we know the view attachment entity exists at this point
                    theMessageViewAttachmentEntity = attachmentEntity
                    //make it invisible to start with
                    theMessageViewAttachmentEntity?.isEnabled = false
                    
                    //attach the attachment on hand
                    handTrackedEntity.addChild(attachmentEntity)
                
                // Add the initial RealityKit content of immerisve entites, which is two globes, now deleted
                if let immersiveContentEntity = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                    content.add(immersiveContentEntity)
                        
                    }
                }
            }
            attachments: {
                Attachment(id: "RandomMessageView") {
                    ZStack {
                        
                        //adding a 3D sphere to replace the 2D circle, used the original scene model in RealityComposerPro
                        Model3D(named: "Scene", bundle: realityKitContentBundle)
                        
                        // Message text
                        Text(appModel.currentMessage)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                           // .padding()
                            .frame(width: 280)
                        
                        Model3D(named: "MagicSparkle", bundle: realityKitContentBundle)
                        
                    }
                }
            }
            .task {
                await setupHandTracking()
            }
        }
    }
    
    //This is where the starting point of the hand tracking is, starting hand tracking ARKitSessionand give HandTrackingProvider
    private func setupHandTracking() async {
        let session = ARKitSession()
        let handTracking = HandTrackingProvider()
        
        do {
            try await session.run([handTracking])
            
            for await update in handTracking.anchorUpdates {
                let handAnchor = update.anchor
                if handAnchor.chirality == .right {
                    //TODO: does this work for .left as well?
                    await updateForHandAnchor(handAnchor)
                }
            }
        } catch {
            print("Error setting up hand tracking: \(error)")
        }
    }
    
    func updateForHandAnchor(_ handAnchor: HandAnchor) async {
        if let handSkeleton = handAnchor.handSkeleton {
            
            let anchorFromForearmWristTransform = handSkeleton.joint(.forearmWrist).anchorFromJointTransform
            let anchorFromForearmWristTransformCombinedWithHandOrigin = handAnchor.originFromAnchorTransform * anchorFromForearmWristTransform
            appModel.latestRightHandForearmWrist = simd_float3(
                anchorFromForearmWristTransformCombinedWithHandOrigin.columns.3.x,
                anchorFromForearmWristTransformCombinedWithHandOrigin.columns.3.y,
                anchorFromForearmWristTransformCombinedWithHandOrigin.columns.3.z
            )
            
            let anchorFromThumbTipTransform = handSkeleton.joint(.thumbTip).anchorFromJointTransform
            let anchorFromThumbTipTransformCombinedWithHandOrigin = handAnchor.originFromAnchorTransform * anchorFromThumbTipTransform
            appModel.latestRightHandThumbTip = simd_float3(
                anchorFromThumbTipTransformCombinedWithHandOrigin.columns.3.x,
                anchorFromThumbTipTransformCombinedWithHandOrigin.columns.3.y,
                anchorFromThumbTipTransformCombinedWithHandOrigin.columns.3.z
            )
            
            let anchorFromMiddleFingerTipTransform = handSkeleton.joint(.middleFingerTip).anchorFromJointTransform
            let anchorFromMiddleFingerTipTransformCombinedWithHandOrigin = handAnchor.originFromAnchorTransform * anchorFromMiddleFingerTipTransform
            appModel.latestRightHandMiddleFingerTip = simd_float3(
                anchorFromMiddleFingerTipTransformCombinedWithHandOrigin.columns.3.x,
                anchorFromMiddleFingerTipTransformCombinedWithHandOrigin.columns.3.y,
                anchorFromMiddleFingerTipTransformCombinedWithHandOrigin.columns.3.z
            )
        }
        
        // Only process palm detection if we have valid coordinates (not all zeros)
        let isValidData = !isZeroVector(appModel.latestRightHandThumbTip) &&
        !isZeroVector(appModel.latestRightHandMiddleFingerTip) &&
        !isZeroVector(appModel.latestRightHandForearmWrist)
        
        if isValidData {
            // Detect palm orientation
            // For palm up: thumb and middle finger should be higher than wrist
            let isPalmUp = appModel.latestRightHandThumbTip.y > appModel.latestRightHandForearmWrist.y &&
            appModel.latestRightHandMiddleFingerTip.y > appModel.latestRightHandForearmWrist.y
            
            // Only update if state has changed
            if isPalmUp != appModel.lastPalmState {
                appModel.lastPalmState = isPalmUp
                appModel.palmStateChangeTime = Date()
                
//                if isPalmUp {
//                    print("Palm up detected!")
//                } else {
//                    print("Palm down detected!")
//                    // NEW: When palm goes down, hide the message
//                    appModel.shouldShowMessage = false
//                }
                
            }
        }
        
        updateJointPositions(for: handAnchor)
        await checkForHandGestures(for: handAnchor)
        
        // Process combined detection
        await checkCombinedGestureDetection()
    }
    
    // Helper function to check if a vector is all zeros
    private func isZeroVector(_ vector: simd_float3) -> Bool {
        return vector.x == 0 && vector.y == 0 && vector.z == 0
    }
    
    func updateJointPositions(for handAnchor: HandAnchor) {
        jointPositions = Dictionary(uniqueKeysWithValues:
                                        HandSkeleton.JointName.allCases.compactMap { jointName in
            guard let joint = handAnchor.handSkeleton?.joint(jointName) else { return nil }
            let worldPosition = handAnchor.originFromAnchorTransform * joint.anchorFromJointTransform.columns.3
            return (jointName, SIMD3<Float>(worldPosition.x, worldPosition.y, worldPosition.z))
        }
        )
    }
    
    func checkForHandGestures(for handAnchor: HandAnchor) async {
        let handInfo = latestHandTracking.generateHandInfo(from: handAnchor)
        if let handInfo {
            await latestHandTracking.updateHandSkeletonEntity(from: handInfo)
        }
        
        let averageAndEachRightScoresForEightBall = latestHandTracking.rightHandVector?.averageAndEachSimilarities(of: .fiveFingers, to: eightBallHandInfo!)
        //  to detect if the hand is in eight ball gesture or not
        if let eightBallAverage = averageAndEachRightScoresForEightBall?.0 {
            let isEightBallGesture = thresholdForEightBallDetection < eightBallAverage
            
            if isEightBallGesture != appModel.isEightBallGestureDetected {
                appModel.isEightBallGestureDetected = isEightBallGesture
                appModel.lastEightBallGestureTime = Date()
                
//                if isEightBallGesture {
//                    print("Eight ball gesture detected! Score: \(eightBallAverage)")
//                } else {
//                    print("Eight ball gesture ended.")
//                    //if the gesture is not complete, the message shouldn't be shown
//                    appModel.shouldShowMessage = false
//                }
            }
            
        }
    }
    
    //creating a function that checks for both gestures and palm state, if both are checked, the message will be revealed
    func checkCombinedGestureDetection() async {
       // print("In checkCombinedGestureDetection")
        let bothGesturesDetected = appModel.lastPalmState && appModel.isEightBallGestureDetected
       
        if bothGesturesDetected{
            print("Both gestures detetcted!")
            
          //haveShownMessage is the second boolean that says to the system that when the mesage is refreshed, secure the message, without further changes
            if(!appModel.haveShownMessage){
                appModel.shouldShowMessage = true
                appModel.refreshMessage()
                appModel.haveShownMessage = true
            }
            
            //and enable the view attachment in a safe way, as it could be nil
            //https://www.hackingwithswift.com/quick-start/understanding-swift/when-to-use-guard-let-rather-than-if-let
            guard let aMessageViewAttachmentEntity = theMessageViewAttachmentEntity else
            {
                return
            }
            //show the ball and the message
            aMessageViewAttachmentEntity.isEnabled = true
               
        } else {
            //if both conditions aren't met, don't show the ball and the message
            appModel.shouldShowMessage = false
            appModel.haveShownMessage = false
            
            //and disable the view attachment
            guard let aMessageViewAttachmentEntity = theMessageViewAttachmentEntity else
            {
                return
            }
            aMessageViewAttachmentEntity.isEnabled = false
        }
        
    }
    
}

//#Preview(immersionStyle: .mixed) {
//    ImmersiveView()
//        .environment(AppModel())
//}

//SUGGESTED: Extension to create visually appealing message transitions (can be changed at any time)
extension AnyTransition {
    static var magicReveal: AnyTransition {
        let insertion = AnyTransition.scale(scale: 0.1)
            .combined(with: .opacity)
            .animation(.spring(response: 0.5, dampingFraction: 0.6))

        let removal = AnyTransition.scale(scale: 1.5)
            .combined(with: .opacity)
            .animation(.easeOut(duration: 0.3))

        return .asymmetric(insertion: insertion, removal: removal)
    }
}

extension String {
    func toModel<T>(_ type: T.Type, using encoding: String.Encoding = .utf8) -> T? where T : Decodable {
        guard let data = self.data(using: encoding) else { return nil }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print(error)
        }
        return nil
    }
}

extension String {
    static let eightBallPosition: String =
"""
{"transform":[[0.010991554,-0.6277732,0.77831864,0],[-0.10841655,-0.7745253,-0.6231824,0],[0.9940447,-0.07753288,-0.07657422,0],[0.114936195,0.98272395,-0.3265768,1]],"chirality":"right","joints":[{"name":"wrist","isTracked":true,"transform":[[1,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1]]},{"name":"thumbKnuckle","isTracked":true,"transform":[[0.58627355,0.5980676,-0.5464415,0],[0.53502464,0.22064468,0.81551486,0],[0.6083024,-0.77047455,-0.1906228,0],[-0.0222974,-0.010139853,0.018547378,1]]},{"name":"thumbIntermediateBase","isTracked":true,"transform":[[0.7391916,0.56882805,-0.36059758,0],[0.38155356,0.08751161,0.92019486,0],[0.554989,-0.81778765,-0.15235052,0],[-0.05126743,-0.038885206,0.04588368,0.99999994]]},{"name":"thumbIntermediateTip","isTracked":true,"transform":[[0.8294096,0.5204541,0.20299633,0],[-0.08334263,-0.24402875,0.9661801,0],[0.55238926,-0.81827724,-0.15902384,0],[-0.07367486,-0.05583197,0.05695807,0.99999994]]},{"name":"thumbTip","isTracked":true,"transform":[[0.82940936,0.520454,0.20299642,0],[-0.08334272,-0.24402882,0.9661797,0],[0.5523892,-0.8182771,-0.15902384,0],[-0.09657978,-0.07034747,0.051240258,0.9999998]]},{"name":"indexFingerMetacarpal","isTracked":true,"transform":[[0.9880289,5.499587e-06,-0.15427057,0],[-0.0005803267,0.9999934,-0.0036810413,0],[0.15426949,0.0037265623,0.988022,0],[-0.023738312,0.0006211698,0.016339533,1]]},{"name":"indexFingerKnuckle","isTracked":true,"transform":[[0.97861874,-0.20562589,0.0047969455,0],[0.20568134,0.97840345,-0.020542197,0],[-0.00046932913,0.021089653,0.9997773,0],[-0.090607904,0.0011826754,0.026892163,1]]},{"name":"indexFingerIntermediateBase","isTracked":true,"transform":[[0.87177783,0.4898456,-0.007400374,0],[-0.48989493,0.8715892,-0.018321197,0],[-0.0025245158,0.019597428,0.99980485,0],[-0.13087954,0.00983208,0.026712097,1]]},{"name":"indexFingerIntermediateTip","isTracked":true,"transform":[[0.5764786,0.81700826,-0.013034009,0],[-0.8171085,0.57635605,-0.012130152,0],[-0.0023982045,0.01764303,0.9998412,0],[-0.1510378,-0.0014497665,0.026892653,0.9999999]]},{"name":"indexFingerTip","isTracked":true,"transform":[[0.5764787,0.8170083,-0.013034054,0],[-0.8171085,0.5763561,-0.012129866,0],[-0.0023979237,0.017642872,0.9998414,0],[-0.16263308,-0.017964926,0.027159927,0.9999999]]},{"name":"middleFingerMetacarpal","isTracked":true,"transform":[[0.9999544,-3.6737183e-05,0.00956897,0],[6.8674286e-05,0.9999947,-0.003339649,0],[-0.0095687825,0.0033401828,0.9999488,0],[-0.025462726,0.00025120378,0.00404492,1]]},{"name":"middleFingerKnuckle","isTracked":true,"transform":[[0.89718616,-0.37803316,0.22836019,0],[0.41084984,0.9041022,-0.11748212,0],[-0.16204876,0.1992251,0.96646255,0],[-0.08949911,0.00054976344,0.0034599158,1]]},{"name":"middleFingerIntermediateBase","isTracked":true,"transform":[[0.8663403,0.49351543,0.07679227,0],[-0.45661736,0.8449177,-0.27859423,0],[-0.20237365,0.20629278,0.957334,0],[-0.13116913,0.018115463,-0.007189624,1]]},{"name":"middleFingerIntermediateTip","isTracked":true,"transform":[[0.5640516,0.8241115,-0.051830366,0],[-0.7993571,0.52921355,-0.28453737,0],[-0.2070612,0.20192471,0.95726305,0],[-0.15463157,0.004738897,-0.00927713,1]]},{"name":"middleFingerTip","isTracked":true,"transform":[[0.5640516,0.8241113,-0.0518303,0],[-0.79935694,0.5292135,-0.2845373,0],[-0.20706116,0.2019247,0.9572628,0],[-0.16625737,-0.012305104,-0.008195971,0.9999999]]},{"name":"ringFingerMetacarpal","isTracked":true,"transform":[[0.9924704,5.610717e-05,0.1224857,0],[0.0003134881,0.99999565,-0.0029981588,0],[-0.122485325,0.0030140318,0.99246573,0],[-0.025518408,-0.0015774071,-0.0083597,1]]},{"name":"ringFingerKnuckle","isTracked":true,"transform":[[0.89959794,-0.35797584,0.2501541,0],[0.3564275,0.9328131,0.053099625,0],[-0.2523553,0.04139351,0.966749,0],[-0.08609195,-0.0014652016,-0.015855324,1.0000001]]},{"name":"ringFingerIntermediateBase","isTracked":true,"transform":[[0.72769094,0.6688011,0.15222137,0],[-0.64343005,0.7424889,-0.18630184,0],[-0.2376215,0.037626363,0.97062904,0],[-0.12224482,0.01292464,-0.025934136,1.0000001]]},{"name":"ringFingerIntermediateTip","isTracked":true,"transform":[[0.376049,0.92498404,0.054699816,0],[-0.8960748,0.378054,-0.23264858,0],[-0.23587565,0.03847216,0.9710214,0],[-0.14090051,-0.0044073425,-0.029880105,1.0000001]]},{"name":"ringFingerTip","isTracked":true,"transform":[[0.37604892,0.9249842,0.054699812,0],[-0.8960749,0.37805396,-0.23264866,0],[-0.23587571,0.03847219,0.9710216,0],[-0.14838415,-0.023161702,-0.030997919,1.0000002]]},{"name":"littleFingerMetacarpal","isTracked":true,"transform":[[0.97627366,5.3881675e-05,0.21654126,0],[0.00053422427,0.99999654,-0.002657067,0],[-0.21654065,0.002709762,0.9762699,0],[-0.024547303,-0.0035034716,-0.022613473,1]]},{"name":"littleFingerKnuckle","isTracked":true,"transform":[[0.83700764,0.054448705,0.5444755,0],[-0.05617532,0.99833006,-0.01347825,0],[-0.5443001,-0.019304698,0.8386684,0],[-0.07468279,-0.003535926,-0.033776656,1]]},{"name":"littleFingerIntermediateBase","isTracked":true,"transform":[[0.5702942,0.7231898,0.38956577,0],[-0.6120652,0.6904017,-0.385645,0],[-0.5478513,-0.018508438,0.8363712,0],[-0.10195138,-0.005693615,-0.051698342,1.0000001]]},{"name":"littleFingerIntermediateTip","isTracked":true,"transform":[[0.33585614,0.9107145,0.24041648,0],[-0.76586825,0.41262218,-0.4931418,0],[-0.5483125,-0.018502641,0.836069,0],[-0.11227586,-0.019212514,-0.058886953,1.0000001]]},{"name":"littleFingerTip","isTracked":true,"transform":[[0.33585614,0.91071445,0.24041654,0],[-0.7658683,0.4126222,-0.49314195,0],[-0.54831266,-0.018502684,0.8360687,0],[-0.11827909,-0.036114387,-0.06331912,1]]},{"name":"forearmWrist","isTracked":true,"transform":[[-0.9614811,-0.13649754,-0.23858488,0],[-0.13995709,0.9901545,-0.0024626732,0],[0.23657194,0.031023739,-0.97111857,0],[6.519258e-09,-2.9802322e-08,-2.9802322e-08,0.9999999]]},{"name":"forearmArm","isTracked":true,"transform":[[-0.96148103,-0.13649754,-0.23858486,0],[-0.13995703,0.99015445,-0.0024626553,0],[0.23657192,0.031023735,-0.9711185,0],[0.24802051,0.046233494,0.06337401,1]]}],"name":"right"}
"""
}
