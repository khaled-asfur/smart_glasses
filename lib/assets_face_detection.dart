// import 'dart:async';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart' show rootBundle;
// import 'package:image/image.dart' as img;
// import 'package:tflite_flutter/tflite_flutter.dart';
//
// void main() {
//   runApp(BlazeFaceApp());
// }
//
// class BlazeFaceApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'BlazeFace Detection',
//       home: FaceDetectionScreen(),
//     );
//   }
// }
//
// class FaceDetectionScreen extends StatefulWidget {
//   @override
//   _FaceDetectionScreenState createState() => _FaceDetectionScreenState();
// }
//
// class _FaceDetectionScreenState extends State<FaceDetectionScreen> {
//   Interpreter? _interpreter;
//   img.Image? _originalImage;      // Decoded image from asset
//   Uint8List? _originalImageBytes; // Raw bytes for display
//   Rect? _detectedBox;             // Bounding box for detected face
//   String _status = 'Loading...';
//
//   // Model input dimensions (adjust as needed for your model)
//   final int _inputWidth = 128;
//   final int _inputHeight = 128;
//   final int _inputChannels = 3;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadModelAndProcessImage();
//   }
//
//   Future<void> _loadModelAndProcessImage() async {
//     try {
//       // 1. Load the BlazeFace model from assets.
//       _interpreter = await Interpreter.fromAsset('assets/models/ultraface.tflite');
//       print('Model loaded.');
//
//       // 2. Load the asset image.
//       final ByteData imageData = await rootBundle.load('assets/images/im.jpg');
//       _originalImageBytes = imageData.buffer.asUint8List();
//
//       // 3. Decode the image using the image package.
//       _originalImage = img.decodeImage(_originalImageBytes!);
//       if (_originalImage == null) {
//         setState(() {
//           _status = 'Failed to decode asset image';
//         });
//         return;
//       }
//
//       // 4. Run face detection on the image.
//       await _runFaceDetection();
//
//       setState(() {
//         _status = 'Detection complete';
//       });
//     } catch (e) {
//       print('Error: $e');
//       setState(() {
//         _status = 'Error: $e';
//       });
//     }
//   }
//
//   Future<void> _runFaceDetection() async {
//     if (_interpreter == null || _originalImage == null) return;
//
//     // Resize the image to the model's expected input size.
//     img.Image resizedImage = img.copyResize(_originalImage!, width: _inputWidth, height: _inputHeight);
//
//     // Convert the resized image into a normalized flat Float32List.
//     Float32List flatInput = _imageToFloat32List(resizedImage, _inputWidth, _inputHeight);
//
//     // Convert the flat input into a 4D tensor with shape [1, height, width, channels].
//     var inputTensor = _convertTo4DTensor(flatInput, _inputHeight, _inputWidth, _inputChannels);
//
//     // Query the model for its output tensor shape.
//     var outputTensor = _interpreter!.getOutputTensor(0);
//     var outputShape = outputTensor.shape; // For example: [1, 896, 16]
//     int outputSize = outputShape.reduce((a, b) => a * b);
//
//     // Allocate an output buffer and reshape it.
//     var outputBuffer = List.filled(outputSize, 0.0).reshape(outputShape);
//
//     // Run inference.
//     _interpreter!.run(inputTensor, outputBuffer);
//     print("Output buffer: $outputBuffer");
//
//     // Ensure that outputBuffer is structured as expected.
//     if (outputBuffer.isEmpty || outputBuffer[0] == null) {
//       print("Output buffer structure is invalid.");
//       return;
//     }
//
//     // Parse the output.
//     // Assume outputBuffer is structured as [1, numDetections, 16]
//     // and that for each detection, index 0 is the score and indices 1-4 are the bounding box.
//     int numDetections = outputShape[1];
//     double detectionThreshold = 0.5;
//     Rect? box;
//
//     // outputBuffer[0] should be a List (one batch element).
//     var detections = outputBuffer[0];
//     if (detections is List) {
//       for (var detection in detections) {
//         if (detection == null) continue; // Skip null detections.
//         // Each detection is expected to be a List of numbers.
//         if (detection is List && detection.length >= 5) {
//           double score = detection[0] ?? 0.0;
//           if (score > detectionThreshold) {
//             double x1 = detection[1] ?? 0.0;
//             double y1 = detection[2] ?? 0.0;
//             double x2 = detection[3] ?? 0.0;
//             double y2 = detection[4] ?? 0.0;
//
//             // Map normalized coordinates (relative to input dimensions) back to original image size.
//             double scaleX = _originalImage!.width / _inputWidth;
//             double scaleY = _originalImage!.height / _inputHeight;
//             box = Rect.fromLTWH(
//               x1 * _inputWidth * scaleX,
//               y1 * _inputHeight * scaleY,
//               (x2 - x1) * _inputWidth * scaleX,
//               (y2 - y1) * _inputHeight * scaleY,
//             );
//             break; // Use the first detection above threshold.
//           }
//         }
//       }
//     } else {
//       print("Unexpected output buffer format.");
//     }
//     setState(() {
//       _detectedBox = box;
//     });
//   }
//
//   /// Converts an [img.Image] to a normalized flat Float32List.
//   Float32List _imageToFloat32List(img.Image image, int inputWidth, int inputHeight) {
//     const int channels = 3;
//     Float32List convertedBytes = Float32List(inputWidth * inputHeight * channels);
//     int pixelIndex = 0;
//     for (int y = 0; y < inputHeight; y++) {
//       for (int x = 0; x < inputWidth; x++) {
//         var pixel = image.getPixel(x, y);
//         double r = pixel.r / 255.0;
//         double g = pixel.g / 255.0;
//         double b = pixel.b / 255.0;
//         convertedBytes[pixelIndex++] = r;
//         convertedBytes[pixelIndex++] = g;
//         convertedBytes[pixelIndex++] = b;
//       }
//     }
//     return convertedBytes;
//   }
//
//   /// Converts a flat [Float32List] into a nested 4D tensor with shape [1, height, width, channels].
//   List<List<List<List<double>>>> _convertTo4DTensor(
//       Float32List flatInput, int height, int width, int channels) {
//     List<List<List<List<double>>>> tensor = [];
//     List<List<List<double>>> batch = List.generate(height, (h) {
//       return List.generate(width, (w) {
//         int baseIndex = (h * width + w) * channels;
//         return List.generate(channels, (c) => flatInput[baseIndex + c]);
//       });
//     });
//     tensor.add(batch);
//     return tensor;
//   }
//
//   @override
//   void dispose() {
//     _interpreter?.close();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('BlazeFace Detection'),
//       ),
//       body: Center(
//         child: _originalImageBytes != null
//             ? Stack(
//           children: [
//             // Display the asset image.
//             Image.memory(_originalImageBytes!),
//             // If a face is detected, overlay a red rectangle.
//             if (_detectedBox != null)
//               Positioned(
//                 left: _detectedBox!.left,
//                 top: _detectedBox!.top,
//                 child: Container(
//                   width: _detectedBox!.width,
//                   height: _detectedBox!.height,
//                   decoration: BoxDecoration(
//                     border: Border.all(color: Colors.red, width: 3),
//                   ),
//                 ),
//               ),
//           ],
//         )
//             : Text(_status),
//       ),
//     );
//   }
// }
