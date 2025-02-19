import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tflite;
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import 'dart:typed_data';

class FaceRecognitionScreen extends StatefulWidget {
  const FaceRecognitionScreen({super.key});

  @override
  State<FaceRecognitionScreen> createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
  late tflite.Interpreter _interpreter;
  bool _isLoading = true;
  String _errorMessage = '';
  img.Image? _processedImage;
  ui.Image? _flutterImage;
  List<DetectionResult> _faces = [];

  @override
  void initState() {
    super.initState();
    _initializeModel();
  }

  Future<void> _initializeModel() async {
    try {
      // Load model
      _interpreter = await tflite.Interpreter.fromAsset(
        'assets/models/yolov8n-face_full_integer_quant_fixed.tflite',
        options: tflite.InterpreterOptions()..threads = 4,
      );

      _verifyModel();

      // Process image
      final inputImage = await _loadAndProcessImage();
      final inputTensor = _imageToTensor(inputImage);
      // Run inference and get results
      final results = await _runInference(inputTensor);

      // Convert to Flutter Image and run inference
      final pngBytes = Uint8List.fromList(img.encodePng(inputImage));
      _flutterImage = await decodeImageFromList(pngBytes);

      setState(() {
        _faces = results;
        _isLoading = false;
      });
    } catch (e) {
      print('error: $e');
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<List<DetectionResult>> _runInference(Uint8List inputTensor) async {
    try {
      // Reshape input as required: [1, 352, 352, 3]
      final input = inputTensor.buffer.asUint8List().reshape([1, 352, 352, 3]);

      // Create the output structure with the shape [1, 300, 21]
      final List<List<List<int>>> output = List.generate(
        1,
        (_) => List.generate(
          300,
          (_) => List.filled(21, 0), // Fill with zeros initially
        ),
      );

      // Run inference: Pass the correctly shaped output
      _interpreter.run(input, output);

      // Parse the results
      return _parseOutputs(output);
    } catch (e) {
      print('Inference failed: $e');
      throw Exception('Inference failed: $e');
    }
  }

  List<DetectionResult> _parseOutputs(List<List<List<dynamic>>> output) {
    final results = <DetectionResult>[];
    const confidenceThreshold = 0.5;

    // Output shape: [1, 300, 21]
    final detections = output[0]; // Access batch dimension

    for (int i = 0; i < 300; i++) {
      final detection = detections[i];
      final confidence = detection[4].toDouble();

      if (confidence > confidenceThreshold) {
        final y1 = detection[0].toDouble() + 352;
        final x1 = detection[1].toDouble() + 352;
        final y2 = detection[2].toDouble() + 352;
        final x2 = detection[3].toDouble() + 352;

        // Ensure proper ordering:
        final left = min<double>(x1, x2);
        final right = max<double>(x1, x2);
        final top = min<double>(y1, y2);
        final bottom = max<double>(y1, y2);

        results.add(DetectionResult(
          Rect.fromLTRB(left, top, right, bottom),
          confidence,
        ));
      }
    }
    return _nonMaxSuppression(results, 0.4);
  }
 // List<DetectionResult> _parseOutputs(dynamic output, bool isQuantized) {
  //   final results = <DetectionResult>[];
  //   const confidenceThreshold = 0.5;
  //
  //   // Quantization parameters (get from model if available)
  //   final quantScale = 0.003921568859368563;  // 1/255
  //   final quantZeroPoint = 0;
  //
  //   for (int i = 0; i < 300; i++) {
  //     final baseIndex = i * 21;
  //
  //     // Get confidence score with dequantization
  //     double confidence;
  //     if (isQuantized) {
  //       final rawConfidence = output[baseIndex + 4];
  //       confidence = (rawConfidence - quantZeroPoint) * quantScale;
  //     } else {
  //       confidence = output[baseIndex + 4];
  //     }
  //
  //     if (confidence > confidenceThreshold) {
  //       // Dequantize bounding box coordinates
  //       double dequantize(int index) {
  //         return isQuantized
  //             ? (output[baseIndex + index] - quantZeroPoint) * quantScale * 352
  //             : output[baseIndex + index] * 352;
  //       }
  //
  //       final y1 = dequantize(0);
  //       final x1 = dequantize(1);
  //       final y2 = dequantize(2);
  //       final x2 = dequantize(3);
  //
  //       results.add(DetectionResult(
  //         Rect.fromLTRB(x1, y1, x2, y2),
  //         confidence,
  //       ));
  //     }
  //   }
  //
  //   return _nonMaxSuppression(results, 0.4);
  // }

  void _verifyModel() {
    // Verify input tensor dimensions
    final inputTensor = _interpreter.getInputTensor(0);
    if (inputTensor.shape[1] != 352 || inputTensor.shape[2] != 352) {
      throw Exception('''Model expects input shape ${inputTensor.shape} 
                     but using 352x352 images''');
    }

    // Verify output tensor dimensions
    final outputTensor = _interpreter.getOutputTensor(0);
    if (outputTensor.shape[1] != 300 || outputTensor.shape[2] != 21) {
      throw Exception('Unexpected output shape ${outputTensor.shape}');
    }
    print('Input shape: ${inputTensor.shape}');
    print('Output shape: ${outputTensor.shape}');
  }


  Future<img.Image> _loadAndProcessImage() async {
    try {
      final byteData = await rootBundle.load('assets/images/img.jpg');
      final originalImage = img.decodeImage(byteData.buffer.asUint8List())!;

      return img
          .copyResize(
            originalImage,
            width: 352,
            height: 352,
          )
          .convert(numChannels: 3); // 3-channel RGB
    } catch (e) {
      print('Image processing failed: $e');
      throw Exception('Image processing failed: $e');
    }
  }

  Uint8List _imageToTensor(img.Image image) {
    final bytes = Uint8List.fromList(image.getBytes());
    if (bytes.length != 352 * 352 * 3) {
      // Updated check
      throw Exception('Need 352x352x3 image (${bytes.length} bytes found)');
    }
    return bytes;
  }

  List<DetectionResult> _nonMaxSuppression(
    List<DetectionResult> results,
    double threshold,
  ) {
    results.sort((a, b) => b.confidence.compareTo(a.confidence));

    final filtered = <DetectionResult>[];
    while (results.isNotEmpty) {
      final current = results.removeAt(0);
      filtered.add(current);
      results.removeWhere(
          (detection) => _iou(current.rect, detection.rect) > threshold);
    }

    return filtered;
  }

  double _iou(Rect a, Rect b) {
    final intersectionLeft = max(a.left, b.left);
    final intersectionTop = max(a.top, b.top);
    final intersectionRight = min(a.right, b.right);
    final intersectionBottom = min(a.bottom, b.bottom);

    if (intersectionRight < intersectionLeft ||
        intersectionBottom < intersectionTop) {
      return 0.0;
    }

    final intersectionArea = (intersectionRight - intersectionLeft) *
        (intersectionBottom - intersectionTop);
    final areaA = a.width * a.height;
    final areaB = b.width * b.height;

    return intersectionArea / (areaA + areaB - intersectionArea);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(child: Text(_errorMessage));
    }

    return Center(
      child: _flutterImage != null
          ? CustomPaint(
        painter: FacePainter(_flutterImage, _faces),
        child: SizedBox(
          width: _flutterImage!.width.toDouble(),
          height: _flutterImage!.height.toDouble(),
        ),
      )
          : const Text('Image not loaded'),
    );
  }
}

class DetectionResult {
  final Rect rect;
  final double confidence;

  DetectionResult(this.rect, this.confidence);
}

// Updated FacePainter
class FacePainter extends CustomPainter {
  final ui.Image? image;
  final List<DetectionResult> faces;

  FacePainter(this.image, this.faces);

  @override
  void paint(Canvas canvas, ui.Size size) {
    if (image != null) {
      final srcRect = Rect.fromLTWH(0, 0, image!.width.toDouble(), image!.height.toDouble());
      final dstRect = _centeredRect(size);
      canvas.drawImageRect(image!, srcRect, dstRect, Paint());

      final scaleX = dstRect.width / image!.width;
      final scaleY = dstRect.height / image!.height;
      final paint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      for (final result in faces) {
        final scaledRect = Rect.fromLTRB(
          result.rect.left * scaleX + dstRect.left,
          result.rect.top * scaleY + dstRect.top,
          result.rect.right * scaleX + dstRect.left,
          result.rect.bottom * scaleY + dstRect.top,
        );
        // Debug print to check coordinates
        debugPrint('Drawing rect: $scaledRect');
        canvas.drawRect(scaledRect, paint);
      }
      canvas.drawRect(
        Rect.fromLTRB(80, 60, 70, 10), // Small rectangle within visible bounds
        Paint()..color = Colors.red,
      );
    }
  }


  Rect _centeredRect(ui.Size availableSize) {
    final imageRatio = image!.width / image!.height;
    final availableRatio = availableSize.width / availableSize.height;

    if (availableRatio > imageRatio) {
      final height = availableSize.height;
      final width = height * imageRatio;
      return Rect.fromLTWH(
        (availableSize.width - width) / 2,
        0,
        width,
        height,
      );
    } else {
      final width = availableSize.width;
      final height = width / imageRatio;
      return Rect.fromLTWH(
        0,
        (availableSize.height - height) / 2,
        width,
        height,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
