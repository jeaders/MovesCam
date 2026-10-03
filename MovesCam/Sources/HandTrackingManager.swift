import Foundation
import Vision
import CoreMedia

@MainActor
class HandTrackingManager: ObservableObject {
    private var handPoseRequest: VNDetectHumanHandPoseRequest!
    private var trackingSequenceRequest: VNSequenceRequestHandler!
    
    @Published var handPoints: [CGPoint] = []
    @Published var detectedHands: Int = 0
    @Published var isDrawingGesture: Bool = false
    @Published var handClosed: Bool = false
    
    private var lastPinchDistance: CGFloat = 0
    private let pinchingThreshold: CGFloat = 0.03
    private let smoothingFactor: CGFloat = 0.4
    private var smoothedPoints: [CGPoint] = []
    
    init() {
        handPoseRequest = VNDetectHumanHandPoseRequest()
        handPoseRequest.maximumHandCount = 2
        trackingSequenceRequest = VNSequenceRequestHandler()
    }
    
    func processFrame(_ sampleBuffer: CMSampleBuffer, imageSize: CGSize) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let requestHandler = VNSequenceRequestHandler()
        let request = VNDetectHumanHandPoseRequest()
        request.maximumHandCount = 2
        
        do {
            try requestHandler.perform([request], on: pixelBuffer)
        } catch {
            return
        }
        
        guard let observations = request.results, !observations.isEmpty else {
            detectedHands = 0
            handPoints = []
            return
        }
        
        detectedHands = observations.count
        var newPoints: [CGPoint] = []
        var closed = false
        
        for observation in observations {
            do {
                let thumbTip = try observation.recognizedPoint(.thumbTip)
                let indexTip = try observation.recognizedPoint(.indexTip)
                let middleTip = try observation.recognizedPoint(.middleTip)
                let ringTip = try observation.recognizedPoint(.ringTip)
                let littleTip = try observation.recognizedPoint(.littleTip)
                
                let wrist = try observation.recognizedPoint(.wrist)
                
                let allFingertips = [thumbTip, indexTip, middleTip, ringTip, littleTip]
                var extendedFingers = 0
                
                for fingertip in allFingertips {
                    if fingertip.confidence > 0.5 && fingertip.y < wrist.y {
                        extendedFingers += 1
                    }
                }
                
                closed = extendedFingers < 2
                handClosed = closed
                
                let pointerPoint = closed ? CGPoint(x: indexTip.location.y, y: indexTip.location.x) : CGPoint(x: indexTip.location.y, y: 1.0 - indexTip.location.x)
                newPoints.append(pointerPoint)
                
            } catch {
                continue
            }
        }
        
        if !newPoints.isEmpty {
            if smoothedPoints.count != newPoints.count {
                smoothedPoints = newPoints
            } else {
                for i in 0..<smoothedPoints.count {
                    smoothedPoints[i].x = smoothingFactor * newPoints[i].x + (1 - smoothingFactor) * smoothedPoints[i].x
                    smoothedPoints[i].y = smoothingFactor * newPoints[i].y + (1 - smoothingFactor) * smoothedPoints[i].y
                }
            }
            
            handPoints = smoothedPoints.map { point in
                CGPoint(
                    x: CGFloat(point.x) * imageSize.width,
                    y: CGFloat(point.y) * imageSize.height
                )
            }
        }
        
        if !newPoints.isEmpty {
            isDrawingGesture = !closed
        }
    }
}
