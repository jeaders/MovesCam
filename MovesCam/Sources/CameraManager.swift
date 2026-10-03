import AVFoundation
import CoreVideo

@MainActor
class CameraManager: ObservableObject {
    private let captureSession = AVCaptureSession()
    private var videoOutput = AVCaptureVideoDataOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?
    
    @Published var currentFrame: CMSampleBuffer?
    @Published var isRunning = false
    @Published var errorMessage: String?
    
    init() {
        setupCamera()
    }
    
    private func setupCamera() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .high
        
        guard let videoDevice = AVCaptureDevice.default(for: .video) else {
            errorMessage = "No camera found"
            return
        }
        
        do {
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            if captureSession.canAddInput(videoDeviceInput) {
                captureSession.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
            }
        } catch {
            errorMessage = "Camera error: \(error.localizedDescription)"
            return
        }
        
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.frame.queue"))
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        captureSession.commitConfiguration()
    }
    
    func startCamera() {
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
                self.isRunning = true
            }
        }
    }
    
    func stopCamera() {
        if captureSession.isRunning {
            captureSession.stopRunning()
            isRunning = false
        }
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        currentFrame = sampleBuffer
    }
}
