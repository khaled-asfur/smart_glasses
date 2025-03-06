import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tflite;
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import 'dart:typed_data';

class FaceRecognitionScreen2 extends StatefulWidget {
  const FaceRecognitionScreen2({super.key});

  @override
  State<FaceRecognitionScreen2> createState() => _FaceRecognitionScreen2State();
}

class _FaceRecognitionScreen2State extends State<FaceRecognitionScreen2> {
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
        debugPrint('Faces initialized with ${_faces.length} faces.');
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
      final input = inputTensor.buffer.asUint8List()/*.reshape([1, 352, 352, 3])*/;

      // Create the output structure with the shape [1, 300, 21]
      final List<List<List<int>>> output = List.generate(
        1,
        (_) => List.generate(
          300,
          (_) => List.filled(21, 0), // Fill with zeros initially
        ),
      );


      _interpreter.run(input, output);

      // Parse the results
      return _parseOutputs(output, 352, 352);
    } catch (e) {
      print('Inference failed: $e');
      throw Exception('Inference failed: $e');
    }
  }

  //Expected values:
  //Rect.fromLTRB(20, 40, 150, 150), output(85,95,130,110
  //Rect.fromLTRB(160, 40, 270, 170), output(215,105,110,130
  // Rect.fromLTRB(276, 75, 351, 190), output(313,265,75,115
  // Output shape: [1, 300, 21]

  // List<FaceDetectionResult> _parseOutputs(
  //     List<List<List<dynamic>>> output, int width, int height) {
  //   final outputTensor = _interpreter.getOutputTensor(0);
  //   final quantParams = outputTensor.params;
  //   final double scale = quantParams.scale;
  //   final int zeroPoint = quantParams.zeroPoint;
  //   const confidenceThreshold = 0.5;
  //
  //   debugPrint('scale = $scale');
  //   debugPrint('zeroPoint = $zeroPoint');
  //
  //   // Output shape: [1, 300, 21]
  //   final results = <FaceDetectionResult>[];
  //   final detections = output[0];
  //   for (final detection in detections) {
  //     final double confidence = (detection[4] - zeroPoint) * scale;
  //
  //     if (confidence > confidenceThreshold) {
  //       debugPrint('Detection confidence: $confidence');
  //       // Assuming detection[0..3] are in normalized corner format (values between 0 and 1)
  //       // Multiply by width/height to get pixel coordinates.
  //       debugPrint("Detection details: $detection");
  //       int index = 0;
  //       final double x1 = ((detection[index] - zeroPoint) * scale) * width;
  //       final double y1 = ((detection[index+1] - zeroPoint) * scale) * height;
  //       final double x2 = ((detection[index+2] - zeroPoint) * scale) * width;
  //       final double y2 = ((detection[index+3] - zeroPoint) * scale) * height;
  //
  //       debugPrint(
  //           'Detection  quantized results from model: Rect.fromLTRB(x1: $x1, y1: $y1, x2: $x2, y2: $y2)');
  //
  //       final double left = x1.clamp(0, width.toDouble());
  //       final double top = y1.clamp(0, height.toDouble());
  //       final double right = x2.clamp(0, width.toDouble());
  //       final double bottom = y2.clamp(0, height.toDouble());
  //
  //       results.add(FaceDetectionResult(
  //         Rect.fromLTRB(left, top, right, bottom),
  //         confidence,
  //       ));
  //       debugPrint(
  //           'Detection accepted: Rect.fromLTRB($left, $top, $right, $bottom)');
  //     }
  //   }
  //
  //   debugPrint('Original results: ${results.length}');
  //   final filteredResults = _nonMaxSuppression(results, 0.4);
  //   debugPrint('Filtered results: ${filteredResults.length}');
  //   return filteredResults;
  // }

// Modify the _parseOutputs method to return correct detections
  List<DetectionResult> _parseOutputs(
      List<List<List<dynamic>>> output, int width, int height) {
    final outputTensor = _interpreter.getOutputTensor(0);
    final quantParams = outputTensor.params;
    final double scale = quantParams.scale;
    final int zeroPoint = quantParams.zeroPoint;
    const confidenceThreshold = 0.5;

    final results = <DetectionResult>[];
    final detections = output[0];

    for (final detection in detections) {
      final double confidence = (detection[4] - zeroPoint) * scale;

      if (confidence > confidenceThreshold) {
        final List<Offset> points = [];

        // Process all 21 elements as individual coordinates
        for (int i = 0; i < 21; i++) {
          // Dequantize value
          double value = (detection[i] - zeroPoint) * scale;
          //double value = detection[i].toDouble();
          // Convert normalized coordinate to pixel position
          // Assume even indices are X, odd are Y (or any other scheme your model uses)
          if (i % 2 == 0) { // Even index: X coordinate
            double x = value * width;
            // Get Y from next element if available
            if (i + 1 < 21) {
              double y = (detection[i + 1] - zeroPoint) * scale * height;
              points.add(Offset(x, y));
            }
          }
        }

        results.add(DetectionResult(points, confidence));
      }
    }

    return results;
  }
  // List<DetectionResult> _parseOutputs(
  //     List<List<List<dynamic>>> output, int width, int height) {
  //   final outputTensor = _interpreter.getOutputTensor(0);
  //   final quantParams = outputTensor.params;
  //   final double scale = quantParams.scale;
  //   final int zeroPoint = quantParams.zeroPoint;
  //   const confidenceThreshold = 0.5;
  //
  //   debugPrint('scale = $scale');
  //   debugPrint('zeroPoint = $zeroPoint');
  //
  //   // Output shape: [1, 300, 21]
  //   final results = <DetectionResult>[];
  //   final detections = output[0];
  //   //(xCenter, yCenter , boxWidth, boxHeight, confidence...) output implementation
  //
  //   for (final detection in detections) {
  //     // Dequantize values
  //     final double xCenter = (detection[0] - zeroPoint) * scale ;
  //     final double yCenter = (detection[1] - zeroPoint) * scale ;
  //     final double boxWidth = (detection[2] - zeroPoint) * scale ;
  //     final double boxHeight = (detection[3] - zeroPoint) * scale ;
  //     final double confidence = (detection[4] - zeroPoint) * scale;
  //
  //     if (confidence > confidenceThreshold) {
  //       debugPrint(
  //                    'Detection   results from model: $detection');
  //       debugPrint('Detection: xCenter: $xCenter, yCenter: $yCenter, boxWidth: $boxWidth, boxHeight: $boxHeight, confidence: $confidence');
  //       // Convert normalized coords to absolute pixels
  //       final double left = (xCenter - boxWidth / 2) * width;
  //       final double top = (yCenter - boxHeight / 2) * height;
  //       final double right = (xCenter + boxWidth / 2) * width;
  //       final double bottom = (yCenter + boxHeight / 2) * height;
  //
  //       results.add(DetectionResult(
  //         Rect.fromLTRB(
  //           left.clamp(0, width.toDouble()),
  //           top.clamp(0, height.toDouble()),
  //           right.clamp(0, width.toDouble()),
  //           bottom.clamp(0, height.toDouble()),
  //         ),
  //         confidence,
  //       ));
  //     }
  //   }
  //   return _nonMaxSuppression(results, 0.4);}




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
      final byteData = await rootBundle.load('assets/images/img9.jpg');
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
    // Quantize input according to model specs: int8 = (uint8_value - 128)
    final inputTensor = Int8List(352 * 352 * 3);
    for (int i = 0; i < bytes.length; i++) {
      inputTensor[i] = (bytes[i] + 128); // Couldn't multiply with the scale as per the model requirement because the list accepts only integer and the scale value is double
    }
    if (bytes.length != 352 * 352 * 3) {
      throw Exception('Need 352x352x3 image (${bytes.length} bytes found)');
    }
    return bytes;
  }

  // List<FaceDetectionResult> _nonMaxSuppression(
  //   List<FaceDetectionResult> results,
  //   double threshold,
  // ) {
  //   results.sort((a, b) => b.confidence.compareTo(a.confidence));
  //
  //   final filtered = <FaceDetectionResult>[];
  //   while (results.isNotEmpty) {
  //     final current = results.removeAt(0);
  //     filtered.add(current);
  //     results.removeWhere(
  //         (detection) => _iou(current.rect, detection.rect) > threshold);
  //   }
  //
  //   return filtered;
  // }

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
              painter: FacePainter( _flutterImage, _faces),
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
  final List<Offset> points;
  final double confidence;

  DetectionResult(this.points, this.confidence);
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

      final paint1 = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill;
      final paint2 = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.fill;
int index =0;
      for (final result in faces) {

                              dynamic paint = paint1;
        if(index==1){
          paint = paint2;
        }
        for (final point in result.points) {
          final scaledX = point.dx * scaleX + dstRect.left;
          final scaledY = point.dy * scaleY + dstRect.top;

          // Draw a dot (small circle)
          canvas.drawCircle(
            Offset(scaledX, scaledY),
            2.0, // Radius
            paint,
          );
        }
        index++;
      }
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}