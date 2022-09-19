/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 The view controller that selects an image and makes a prediction using Vision and Core ML.
 */

import UIKit

class MainViewController: UIViewController {
    var firstRun = true
    
    /// A predictor instance that uses Vision and Core ML to generate prediction strings from a photo.
    let imagePredictor = ImagePredictor()
    
    /// The largest number of predictions the main view controller displays the user.
    let predictionsToShow = 2
    var picker = UIImagePickerController()
    var selectedImage: UIImage = UIImage()
    // MARK: Main storyboard outlets
    
    @IBOutlet weak var predictionLabel: UILabel!
    
    @IBOutlet weak var chooseImageButton: UIButton!
    @IBOutlet weak var selectedImageView: UIImageView!
    
    @IBAction func touchUpTodiagnose(_ sender: Any) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.classifyImage(self.selectedImage)
        }
    }
}

extension MainViewController {
    // MARK: Main storyboard actions
    /// The method the storyboard calls when the user one-finger taps the screen.
    
   
    
    @IBAction func touchUpToShowSheet(_ sender: Any) {
        let alert:UIAlertController=UIAlertController(title: "Choose Image", message: nil, preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { alertAction in
            self.openCamera()
        }
        
        let gallaryAction = UIAlertAction(title: "Gallary", style: .default)
        {
            alertAction in
            self.openPhotoLibrary()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        {
            UIAlertAction in
            
        }
        // Add the actions
        picker.delegate = self
        alert.addAction(cameraAction)
        alert.addAction(gallaryAction)
        alert.addAction(cancelAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func singleTap() {
        // Show options for the source picker only if the camera is available.
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            present(photoPicker, animated: false)
            return
        }
        
        present(cameraPicker, animated: false)
    }
    
    /// The method the storyboard calls when the user two-finger taps the screen.
    @IBAction func doubleTap() {
        present(photoPicker, animated: false)
    }
}

extension MainViewController {
    // MARK: Main storyboard updates
    /// Updates the storyboard's image view.
    /// - Parameter image: An image.
    func updateImage(_ image: UIImage) {
        DispatchQueue.main.async {
            self.selectedImageView.image = image
            self.selectedImage = image
        }
    }
    
    func openCamera() {
//        picker.sourceType = .camera
//        present(picker, animated: true)
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            present(photoPicker, animated: false)
            return
        }
        
        present(cameraPicker, animated: false)
    }
    
    func openPhotoLibrary() {
//        picker.sourceType = .photoLibrary
//        present(picker, animated: true)
        present(photoPicker, animated: false)
    }
    
    /// Updates the storyboard's prediction label.
    /// - Parameter message: A prediction or message string.
    /// - Tag: updatePredictionLabel
    func updatePredictionLabel(_ message: String) {
        DispatchQueue.main.async {
            self.predictionLabel.text = message
        }
        
        if firstRun {
            DispatchQueue.main.async {
                self.firstRun = false
                self.predictionLabel.superview?.isHidden = false
            }
        }
    }
    /// Notifies the view controller when a user selects a photo in the camera picker or photo library picker.
    /// - Parameter photo: A photo from the camera or photo library.
    func userSelectedPhoto(_ photo: UIImage) {
        updateImage(photo)
        updatePredictionLabel("정확한 진단을 위해 위 예시와 유사한 사진인지 확인해주세요!")
        
//        DispatchQueue.global(qos: .userInitiated).async {
//            self.classifyImage(photo)
//        }
    }
}

extension MainViewController {
    // MARK: Image prediction methods
    /// Sends a photo to the Image Predictor to get a prediction of its content.
    /// - Parameter image: A photo.
    private func classifyImage(_ image: UIImage) {
        do {
            try self.imagePredictor.makePredictions(for: image,
                                                    completionHandler: imagePredictionHandler)
        } catch {
            print("Vision was unable to make a prediction...\n\n\(error.localizedDescription)")
        }
    }
    
    /// The method the Image Predictor calls when its image classifier model generates a prediction.
    /// - Parameter predictions: An array of predictions.
    /// - Tag: imagePredictionHandler
    private func imagePredictionHandler(_ predictions: [ImagePredictor.Prediction]?) {
        guard let predictions = predictions else {
            updatePredictionLabel("No predictions. (Check console log.)")
            return
        }
        
        let formattedPredictions = formatPredictions(predictions)
        let translatePredictions: String = {
            var text = String()
            if formattedPredictions[0] == "pseudostrabismus" {
                text = "가성내사시"
            } else {
                text = "영아내사시"
            }
            return text
        }()
        
//        let predictionString = formattedPredictions.joined(separator: "\n")
        updatePredictionLabel("\(translatePredictions)일 확률이 높습니다.")
    }
    
    /// Converts a prediction's observations into human-readable strings.
    /// - Parameter observations: The classification observations from a Vision request.
    /// - Tag: formatPredictions
    private func formatPredictions(_ predictions: [ImagePredictor.Prediction]) -> [String] {
        // Vision sorts the classifications in descending confidence order.
        let topPredictions: [String] = predictions.prefix(predictionsToShow).map { prediction in
            var name = prediction.classification
            
            // For classifications with more than one name, keep the one before the first comma.
            if let firstComma = name.firstIndex(of: ",") {
                name = String(name.prefix(upTo: firstComma))
            }
            
//            return "\(name) - \(prediction.confidencePercentage)%"
            return "\(name)"
        }
        
        return topPredictions
    }
}
