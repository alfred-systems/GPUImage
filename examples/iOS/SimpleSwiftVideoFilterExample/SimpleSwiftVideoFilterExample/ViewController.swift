import UIKit
import GPUImage
import AVFoundation

class ViewController: UIViewController {
    
    var videoCamera:GPUImageVideoCamera?
    var filter:GPUImagePixellateFilter?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        videoCamera = GPUImageVideoCamera(sessionPreset: AVCaptureSession.Preset.vga640x480.rawValue, cameraPosition: .back)
        videoCamera!.outputImageOrientation = .portrait;
        filter = GPUImagePixellateFilter()
        videoCamera?.addTarget(filter)
        filter?.addTarget(self.view as! GPUImageView)
        videoCamera?.startCapture()
    }
}
