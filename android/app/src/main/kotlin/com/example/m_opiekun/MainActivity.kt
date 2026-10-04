package com.example.m_opiekun

import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "m_opiekun/prescription_ocr"
        ).setMethodCallHandler { call, result ->
            if (call.method != "recognizeText") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val path = call.argument<String>("path")
            if (path == null) {
                result.error("invalid_image", "Brak ścieżki obrazu strony PDF.", null)
                return@setMethodCallHandler
            }

            val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
            try {
                recognizer.process(InputImage.fromFilePath(this, path))
                    .addOnSuccessListener { visionText -> result.success(visionText.text) }
                    .addOnFailureListener {
                        result.error("ocr_failed", "Nie udało się rozpoznać tekstu na obrazie.", null)
                    }
                    .addOnCompleteListener { recognizer.close() }
            } catch (error: Exception) {
                recognizer.close()
                result.error("ocr_failed", "Nie udało się otworzyć obrazu strony PDF.", error.javaClass.simpleName)
            }
        }
    }
}
