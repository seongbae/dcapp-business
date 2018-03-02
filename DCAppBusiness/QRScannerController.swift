import UIKit
import AVFoundation
import Alamofire

class QRScannerController: UIViewController {

    @IBOutlet var messageLabel:UILabel!
    @IBOutlet var topbar: UIView!
    
    var captureSession = AVCaptureSession()
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var qrCodeFrameView: UIView?

    private let supportedCodeTypes = [AVMetadataObject.ObjectType.upce,
                                      AVMetadataObject.ObjectType.code39,
                                      AVMetadataObject.ObjectType.code39Mod43,
                                      AVMetadataObject.ObjectType.code93,
                                      AVMetadataObject.ObjectType.code128,
                                      AVMetadataObject.ObjectType.ean8,
                                      AVMetadataObject.ObjectType.ean13,
                                      AVMetadataObject.ObjectType.aztec,
                                      AVMetadataObject.ObjectType.pdf417,
                                      AVMetadataObject.ObjectType.itf14,
                                      AVMetadataObject.ObjectType.dataMatrix,
                                      AVMetadataObject.ObjectType.interleaved2of5,
                                      AVMetadataObject.ObjectType.qr]
   
    override func viewDidLoad() {
        super.viewDidLoad()

        // Get the back-facing camera for capturing videos
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back)
        
        guard let captureDevice = deviceDiscoverySession.devices.first else {
            print("Failed to get the camera device")
            return
        }
        
        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            // Set the input device on the capture session.
            captureSession.addInput(input)
            
            // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession.addOutput(captureMetadataOutput)
            
            // Set delegate and use the default dispatch queue to execute the call back
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = supportedCodeTypes
//            captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
            
        } catch {
            // If any error occurs, simply print it out and don't continue any more.
            print(error)
            return
        }
        
        // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer?.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer!)
        
        // Start video capture.
        captureSession.startRunning()
        
        // Move the message label and top bar to the front
        view.bringSubview(toFront: messageLabel)
        view.bringSubview(toFront: topbar)
        
        // Initialize QR Code Frame to highlight the QR code
        qrCodeFrameView = UIView()
        
        if let qrCodeFrameView = qrCodeFrameView {
            qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
            qrCodeFrameView.layer.borderWidth = 2
            view.addSubview(qrCodeFrameView)
            view.bringSubview(toFront: qrCodeFrameView)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Helper methods

    func launchApp(decodedURL: String) {
        
        if presentedViewController != nil {
            return
        }
        
        let alertPrompt = UIAlertController(title: "Validate Coupon", message: "Are you sure?", preferredStyle: .actionSheet)
        let confirmAction = UIAlertAction(title: "Confirm", style: UIAlertActionStyle.default, handler: { (action) -> Void in
            var couponStatus = ""
            var couponMessage = ""
            
            if let url = URL(string: decodedURL) {
                var dict = [String:String]()
                let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
                if let queryItems = components.queryItems {
                    for item in queryItems {
                        dict[item.name] = item.value!
                    }
                }
                
                let headers: HTTPHeaders = [
                    "Authorization": "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6Ik1UVkNSVFV3TXpWRVFqWkZPRGMyTUVNeE4wSTFPREV3Umpnd05qVkRNalU1TmtJNE16ZEJPUSJ9.eyJpc3MiOiJodHRwczovL2RjYXBwYXV0aC5hdXRoMC5jb20vIiwic3ViIjoiS2lHY2FIVmVaY0dvTWUzTmNVTlpUVlFlNnZORUxJUFVAY2xpZW50cyIsImF1ZCI6Imh0dHBzOi8vZGNhcHBjb3Vwb25zYXBpLmNvbSIsImlhdCI6MTUxOTI3NzcwOSwiZXhwIjoxNTE5MzY0MTA5LCJhenAiOiJLaUdjYUhWZVpjR29NZTNOY1VOWlRWUWU2dk5FTElQVSIsImd0eSI6ImNsaWVudC1jcmVkZW50aWFscyJ9.toIDOiGf5qvZqdcj9dSFJAxqmbE7F_enJu_F-tfc4VZ6c68YbOJcJYskdnBcAosC_u88P5r8quLqOw6lq_113Q4ypTXrIaSgW6HAIFhQI8lEKpfyJgkMsAuiU1QOyBbmmKTGl5G2tFrg8TWaHIYakmazBBKG-0FEQptfk0pZdz8-wsdOydxFJO0RM1JZJeUaCgGI6nWovhBz924gYB2Wm6TWLNt4POdzrRcgEhUSMPgqph1QcjOpzLC_fzHz1xEe9Bw5OTdHjJT32LEWg9Gbxp1ZrdSlxcUl76SAmKKXlJY2uTbVImeNqebwfWjW0fCwWOtfHDicWHvmJxruDT6QOQ"
                ]
                
                let parameters: Parameters = [
                    "uniqueid": dict["uniqueid"],
                    "businessid": dict["businessid"],
                    "couponid": dict["couponid"]
                ]
                
                Alamofire.request("http://coupons.dcapp.org/api/validate", method: .post, parameters: parameters,encoding: JSONEncoding.default, headers: headers).validate(statusCode: 201..<300).responseJSON {
                    response in
                    //debugPrint(response)
                    
                    var statusCode = response.response?.statusCode
                    debugPrint(statusCode)
                    
                    var imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
                    
                    // if server returns 201 status code, the coupon is valid
                    // if server returns 200 status code, the coupon is already used
                    // for any other code, display invalid message
                    if (statusCode == 201)
                    {
                        couponStatus = "Coupon is good"
                        couponMessage = "15% off on Jja Jang Myun"  // will eventually be replaced with whatever message that comes back from server
                        imageView.image = UIImage(named:"greencheckmark")
                    }
                    else if (statusCode == 200)
                    {
                        couponStatus = "Coupon has been used already"
                        couponMessage = ""
                        imageView.image = UIImage(named:"redx")
                    }
                    else
                    {
                        couponStatus = "Coupon is invalid"
                        couponMessage = ""
                        imageView.image = UIImage(named:"redx")
                    }
                    
                    let alertPrompt = UIAlertController(title: couponStatus, message: couponMessage, preferredStyle: .actionSheet)
                    
                    alertPrompt.view.addSubview(imageView)
                    alertPrompt.addAction(UIAlertAction(title: "Close", style: UIAlertActionStyle.cancel, handler: nil))
                    var height:NSLayoutConstraint = NSLayoutConstraint(item: alertPrompt.view, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: self.view.frame.height * 0.50)
                    alertPrompt.view.addConstraint(height);
                    self.present(alertPrompt, animated: true, completion: nil)
                }
            }
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
        
        alertPrompt.addAction(confirmAction)
        alertPrompt.addAction(cancelAction)
        
        present(alertPrompt, animated: true, completion: nil)
    }

}

extension QRScannerController: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRect.zero
            messageLabel.text = "No QR code is detected"
            return
        }
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if supportedCodeTypes.contains(metadataObj.type) {
            // If the found metadata is equal to the QR code metadata (or barcode) then update the status label's text and set the bounds
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds
            
            if metadataObj.stringValue != nil {
                launchApp(decodedURL: metadataObj.stringValue!)
                messageLabel.text = metadataObj.stringValue
                
            }
        }
    }
    
}
