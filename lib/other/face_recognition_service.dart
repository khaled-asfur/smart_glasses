import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:math';

class FaceRecognitionService {
  late Interpreter _interpreter;

  Future<void> initialize() async {
    _interpreter = await Interpreter.fromAsset('mobilefacenet.tflite');
  }

  Future<List<double>> getEmbedding(img.Image faceImage) async {
    img.Image resized = img.copyResize(faceImage, width: 112, height: 112);
    var input = _preprocessImage(resized);
    var output = List.filled(1 * 128, 0.0).reshape([1, 128]);
    _interpreter.run(input, output);
    return output[0];
  }

  Float32List _preprocessImage(img.Image image) {
    var inputBuffer = Float32List(112 * 112 * 3);
    int index = 0;

    for (int y = 0; y < 112; y++) {
      for (int x = 0; x < 112; x++) {
        int color = image.getPixel(x, y);
        inputBuffer[index++] = ((color >> 16) & 0xFF - 127.5) / 128.0; // R
        inputBuffer[index++] = ((color >> 8) & 0xFF - 127.5) / 128.0;  // G
        inputBuffer[index++] = (color & 0xFF - 127.5) / 128.0;         // B
      }
    }
    return inputBuffer;
  }

  double cosineSimilarity(List<double> a, List<double> b) {
    double dot = 0.0, normA = 0.0, normB = 0.0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    return dot / (sqrt(normA) * sqrt(normB));
  }

  void dispose() {
    _interpreter.close();
  }
}