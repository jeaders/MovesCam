import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var handTrackingManager = HandTrackingManager()
    
    @State private var showCameraPreview: Bool = true
    @State private var drawColor: Color = .blue
    @State private var drawWidth: CGFloat = 4.0
    @State private var showHelp: Bool = false
    
    @State private var activeHandPoints: [CGPoint] = []
    @State private var detectedHandCount: Int = 0
    @State private var handClosed: Bool = false
    @State private var currentPath: DrawingPath?
    @State private var paths: [DrawingPath] = []
    @State private var pointerLocations: [CGPoint] = []
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("MovesCam")
                            .font(.title.bold())
                        Spacer()
                        Button(action: { showHelp.toggle() }) {
                            Image(systemName: "questionmark.circle")
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    HStack(spacing: 12) {
                        Toggle("Show Camera", isOn: $showCameraPreview)
                            .toggleStyle(.switch)
                        
                        Button(action: {
                            paths = []
                            currentPath = nil
                            pointerLocations = []
                        }) {
                            Text("Clear")
                        }
                        .disabled(paths.isEmpty && currentPath == nil)
                        
                        Button(action: {
                            if cameraManager.isRunning {
                                cameraManager.stopCamera()
                            } else {
                                cameraManager.startCamera()
                            }
                        }) {
                            Text(cameraManager.isRunning ? "Stop Camera" : "Start Camera")
                        }
                    }
                    
                    HStack(spacing: 8) {
                        Text("Color:")
                        ForEach([Color.blue, Color.red, Color.green, Color.orange, Color.purple], id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Circle().stroke(Color.primary, lineWidth: drawColor == color ? 2 : 0)
                                )
                                .onTapGesture {
                                    drawColor = color
                                }
                        }
                    }
                    
                    HStack(spacing: 12) {
                        Text("Width:")
                        Slider(value: $drawWidth, in: 1...20, step: 1)
                            .frame(width: 120)
                        Text("\(Int(drawWidth))")
                            .frame(width: 30, alignment: .trailing)
                    }
                    
                    if showHelp {
                        Divider()
                        VStack(alignment: .leading, spacing: 4) {
                            Text("How to use:")
                                .font(.caption.bold())
                            Text("• Turn on camera")
                            Text("• Open hand = draw")
                            Text("• Close fist = stop drawing")
                            Text("• Use your index finger as a pen")
                            Text("• Point at the camera")
                            Text("• Adjust color and width")
                        }
                        .font(.caption)
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            GeometryReader { geometry in
                ZStack {
                    if showCameraPreview {
                        CameraPreviewView(sampleBuffer: cameraManager.currentFrame)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .overlay(
                                RoundedRectangle(cornerRadius: 0)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    DrawingCanvasView(
                        paths: $paths,
                        currentPath: $currentPath,
                        handPoints: $activeHandPoints,
                        pointerLocations: $pointerLocations,
                        drawColor: $drawColor,
                        drawWidth: $drawWidth,
                        handClosed: $handClosed,
                        detectedHandCount: $detectedHandCount
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white)
                }
            }
        }
        .frame(minWidth: 1000, minHeight: 700)
        .onAppear {
            cameraManager.startCamera()
            
            Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { _ in
                guard let sampleBuffer = cameraManager.currentFrame else { return }
                
                guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
                let imageSize = CGSize(
                    width: CGFloat(CVPixelBufferGetWidth(pixelBuffer)),
                    height: CGFloat(CVPixelBufferGetHeight(pixelBuffer))
                )
                
                handTrackingManager.processFrame(sampleBuffer, imageSize: imageSize)
                
                DispatchQueue.main.async {
                    activeHandPoints = handTrackingManager.handPoints
                    detectedHandCount = handTrackingManager.detectedHands
                    handClosed = handTrackingManager.handClosed
                    
                    let isDrawingGesture = handTrackingManager.isDrawingGesture && detectedHandCount > 0
                    
                    if isDrawingGesture, let firstPoint = activeHandPoints.first {
                        if currentPath == nil {
                            currentPath = DrawingPath(points: [firstPoint], color: drawColor, lineWidth: drawWidth)
                        } else {
                            let lastPoint = currentPath!.points.last!
                            let distance = hypot(firstPoint.x - lastPoint.x, firstPoint.y - lastPoint.y)
                            if distance > 2.0 {
                                currentPath?.points.append(firstPoint)
                            }
                        }
                        pointerLocations = [firstPoint]
                    } else {
                        if let path = currentPath {
                            paths.append(path)
                        }
                        currentPath = nil
                        pointerLocations = []
                    }
                }
            }
        }
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let sampleBuffer: CMSampleBuffer?
    
    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }
    
    func updateUIView(_ uiView: UIImageView, context: Context) {
        guard let sampleBuffer = sampleBuffer else {
            uiView.image = nil
            return
        }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        
        let imageRect = CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
        
        let mirroredImage = ciImage.oriented(forExifOrientation: 6)
        
        if let cgImage = context.createCGImage(mirroredImage, from: imageRect) {
            uiView.image = UIImage(cgImage: cgImage)
        }
    }
}

struct DrawingCanvasView: View {
    @Binding var paths: [DrawingPath]
    @Binding var currentPath: DrawingPath?
    @Binding var handPoints: [CGPoint]
    @Binding var pointerLocations: [CGPoint]
    @Binding var drawColor: Color
    @Binding var drawWidth: CGFloat
    @Binding var handClosed: Bool
    @Binding var detectedHandCount: Int
    
    var body: some View {
        ZStack {
            Color.white
            
            ForEach(paths) { path in
                Path { pathPath in
                    if let first = path.points.first {
                        pathPath.move(to: first)
                        for point in path.points.dropFirst() {
                            pathPath.addLine(to: point)
                        }
                    }
                }
                .stroke(path.color, lineWidth: path.lineWidth)
            }
            
            if let currentPath = currentPath {
                Path { pathPath in
                    if let first = currentPath.points.first {
                        pathPath.move(to: first)
                        for point in currentPath.points.dropFirst() {
                            pathPath.addLine(to: point)
                        }
                    }
                }
                .stroke(currentPath.color, lineWidth: currentPath.lineWidth)
            }
            
            ForEach(handPoints.indices, id: \.self) { index in
                if index < handPoints.count {
                    let location = handPoints[index]
                    ZStack {
                        Circle()
                            .fill(handClosed ? Color.red : Color.green)
                            .frame(width: 24, height: 24)
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 24, height: 24)
                    }
                    .position(location)
                }
            }
            
            VStack {
                Spacer()
                HStack {
                    Text(detectedHandCount > 0 ? "✋ Hand detected" : "No hand detected")
                        .font(.caption)
                        .padding(6)
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(6)
                    Spacer()
                }
                .padding()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
