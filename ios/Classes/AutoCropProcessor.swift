import Foundation
import WeScan
import UIKit

/**
 * Processor for auto-cropping image bytes without UI interaction.
 * Converts Data (ByteArray) to UIImage, detects document edges using WeScan,
 * applies perspective correction, and returns the cropped image as Data.
 */
class AutoCropProcessor {

    /**
     * Auto-crop image bytes using WeScan's rectangle detection
     * - Parameter imageBytes: Image data (typically JPEG)
     * - Parameter jpegQuality: JPEG compression quality (0-1.0, default 0.95)
     * - Returns: Cropped image bytes or nil if detection fails
     */
    static func autoCropImageBytes(_ imageBytes: Data, jpegQuality: CGFloat = 0.95) -> Data? {
        do {
            // 1. Convert bytes to UIImage
            guard let originalImage = UIImage(data: imageBytes) else {
                print("Failed to decode image bytes")
                return nil
            }

            // 2. Convert UIImage to CIImage for processing
            guard let ciImage = CIImage(image: originalImage) else {
                print("Failed to convert UIImage to CIImage")
                return nil
            }

            // 3. Detect rectangles using WeScan's VisionRectangleDetector
            let imageSize = ciImage.extent.size
            let detector = CIDetector(ofType: CIDetectorTypeRectangle,
                                     context: CIContext(),
                                     options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])

            guard let detector = detector else {
                print("Failed to create CIDetector")
                return nil
            }

            let features = detector.features(in: ciImage)
            guard let rectFeature = features.first as? CIRectangleFeature else {
                print("No rectangle detected in image")
                return nil
            }

            // 4. Apply perspective correction using the detected rectangle
            var correctionOptions: [String: Any] = [:]
            correctionOptions[CIDetectorAspectRatio] = rectFeature.bounds.width / rectFeature.bounds.height

            // Create perspective correction using the detected corners
            let correctedImage = correctPerspective(ciImage,
                                                   using: rectFeature,
                                                   imageSize: imageSize)

            // 5. Convert back to UIImage
            let croppedUIImage = UIImage(ciImage: correctedImage)

            // 6. Compress to JPEG bytes
            guard let jpegData = croppedUIImage.jpegData(compressionQuality: jpegQuality) else {
                print("Failed to convert image to JPEG data")
                return nil
            }

            print("autoCropImageBytes completed successfully")
            return jpegData

        } catch {
            print("Error in autoCropImageBytes: \(error.localizedDescription)")
            return nil
        }
    }

    /**
     * Apply perspective correction to match the detected rectangle
     */
    private static func correctPerspective(_ ciImage: CIImage,
                                         using rectFeature: CIRectangleFeature,
                                         imageSize: CGSize) -> CIImage {
        // Normalize rectangle coordinates to 0-1 range
        let imageArea = ciImage.extent

        let topLeft = CGPoint(
            x: rectFeature.topLeft.x / imageArea.size.width,
            y: 1 - (rectFeature.topLeft.y / imageArea.size.height)
        )

        let topRight = CGPoint(
            x: rectFeature.topRight.x / imageArea.size.width,
            y: 1 - (rectFeature.topRight.y / imageArea.size.height)
        )

        let bottomLeft = CGPoint(
            x: rectFeature.bottomLeft.x / imageArea.size.width,
            y: 1 - (rectFeature.bottomLeft.y / imageArea.size.height)
        )

        let bottomRight = CGPoint(
            x: rectFeature.bottomRight.x / imageArea.size.width,
            y: 1 - (rectFeature.bottomRight.y / imageArea.size.height)
        )

        // Apply perspective correction filter
        let perspectiveCorrection = "CIPerspectiveCorrection"
        let correctedImage = ciImage.applyingFilter(perspectiveCorrection, parameters: [
            "inputTopLeft": CIVector(cgPoint: topLeft),
            "inputTopRight": CIVector(cgPoint: topRight),
            "inputBottomLeft": CIVector(cgPoint: bottomLeft),
            "inputBottomRight": CIVector(cgPoint: bottomRight)
        ])

        return correctedImage
    }
}
