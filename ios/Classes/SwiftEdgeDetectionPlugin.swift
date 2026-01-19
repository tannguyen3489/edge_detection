import Flutter
import UIKit
import WeScan

public class SwiftEdgeDetectionPlugin: NSObject, FlutterPlugin, UIApplicationDelegate {
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "edge_detection", binaryMessenger: registrar.messenger())
        let instance = SwiftEdgeDetectionPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as! Dictionary<String, Any>

        if (call.method == "edge_detect") {
            let saveTo = args["save_to"] as! String
            let canUseGallery = args["can_use_gallery"] as? Bool ?? false

            if let viewController = UIApplication.shared.delegate?.window??.rootViewController as? FlutterViewController {
                let destinationViewController = HomeViewController()
                destinationViewController.setParams(saveTo: saveTo, canUseGallery: canUseGallery)
                destinationViewController._result = result
                viewController.present(destinationViewController,animated: true,completion: nil);
            }
        }
        else if (call.method == "edge_detect_gallery") {
            let saveTo = args["save_to"] as! String
            let canUseGallery = args["can_use_gallery"] as? Bool ?? false

            if let viewController = UIApplication.shared.delegate?.window??.rootViewController as? FlutterViewController {
                let destinationViewController = HomeViewController()
                destinationViewController.setParams(saveTo: saveTo, canUseGallery: canUseGallery)
                destinationViewController._result = result
                destinationViewController.selectPhoto();
            }
        }
        else if (call.method == "auto_crop") {
            handleAutoCrop(call, result: result)
        }
        else if (call.method == "process_image") {
            handleProcessImage(call, result: result)
        }
        else {
            result(FlutterMethodNotImplemented)
        }
    }

    private func handleAutoCrop(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? Dictionary<String, Any> else {
            result(FlutterError(code: "invalid_argument", message: "Arguments must be a dictionary", details: nil))
            return
        }

        guard let imageBytes = args["image_bytes"] as? FlutterStandardTypedData else {
            result(FlutterError(code: "invalid_argument", message: "image_bytes is required and must be bytes", details: nil))
            return
        }

        // Process auto-crop in background thread to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async {
            let data = imageBytes.data
            let croppedBytes = AutoCropProcessor.autoCropImageBytes(data)

            DispatchQueue.main.async {
                if let croppedBytes = croppedBytes {
                    result(FlutterStandardTypedData(bytes: croppedBytes))
                } else {
                    result(FlutterError(
                        code: "crop_failed",
                        message: "Failed to detect or crop image edges",
                        details: nil
                    ))
                }
            }
        }
    }

    private func handleProcessImage(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? Dictionary<String, Any> else {
            result(FlutterError(code: "invalid_argument", message: "Arguments must be a dictionary", details: nil))
            return
        }

        let imagePath = args["image_path"] as? String
        let imageBytes = args["image_bytes"] as? FlutterStandardTypedData

        if imagePath == nil && imageBytes == nil {
            result(FlutterError(code: "invalid_argument", message: "Either image_path or image_bytes is required", details: nil))
            return
        }

        // Process in background thread to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async {
            var dataToProcess: Data?

            if let imagePath = imagePath {
                // Read image from file path
                do {
                    dataToProcess = try Data(contentsOf: URL(fileURLWithPath: imagePath))
                } catch {
                    DispatchQueue.main.async {
                        result(FlutterError(code: "invalid_argument", message: "Failed to read file: \(error.localizedDescription)", details: nil))
                    }
                    return
                }
            } else if let imageBytes = imageBytes {
                dataToProcess = imageBytes.data
            }

            guard let data = dataToProcess else {
                DispatchQueue.main.async {
                    result(FlutterError(code: "invalid_argument", message: "Failed to load image data", details: nil))
                }
                return
            }

            let croppedBytes = AutoCropProcessor.autoCropImageBytes(data)

            DispatchQueue.main.async {
                if let croppedBytes = croppedBytes {
                    result(FlutterStandardTypedData(bytes: croppedBytes))
                } else {
                    result(FlutterError(
                        code: "crop_failed",
                        message: "Failed to detect or crop image edges",
                        details: nil
                    ))
                }
            }
        }
    }
}

