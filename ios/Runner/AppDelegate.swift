import Flutter
import UIKit
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: "m_opiekun/prescription_ocr",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "recognizeText",
            let arguments = call.arguments as? [String: Any],
            let path = arguments["path"] as? String,
            let image = UIImage(contentsOfFile: path)?.cgImage
      else {
        result(FlutterError(
          code: "invalid_image",
          message: "Nie można otworzyć obrazu strony PDF.",
          details: nil
        ))
        return
      }

      DispatchQueue.global(qos: .userInitiated).async {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["pl-PL", "en-US"]
        request.usesLanguageCorrection = false

        do {
          try VNImageRequestHandler(cgImage: image).perform([request])
          let lines = (request.results ?? []).sorted { first, second in
            let verticalDifference = first.boundingBox.midY - second.boundingBox.midY
            return abs(verticalDifference) < 0.01
              ? first.boundingBox.minX < second.boundingBox.minX
              : verticalDifference > 0
          }
          let text = lines.compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n")
          DispatchQueue.main.async { result(text) }
        } catch {
          DispatchQueue.main.async {
            result(FlutterError(
              code: "ocr_failed",
              message: "Nie udało się rozpoznać tekstu na obrazie.",
              details: nil
            ))
          }
        }
      }
    }
  }
}
