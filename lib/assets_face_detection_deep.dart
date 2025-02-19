// import 'dart:async';
// import 'dart:typed_data';
// import 'dart:ui' as ui;
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:tflite_flutter/tflite_flutter.dart';
// import 'package:image/image.dart' as img;
//
// void main() => runApp(const FaceDetectionApp());
//
// class FaceDetectionApp extends StatelessWidget {
//   const FaceDetectionApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'UltraFace Demo',
//       theme: ThemeData(primarySwatch: Colors.blue),
//       home: const FaceDetectionScreen(),
//     );
//   }
// }
//
// class FaceDetectionScreen extends StatefulWidget {
//   const FaceDetectionScreen({super.key});
//
//   @override
//   State<FaceDetectionScreen> createState() => _FaceDetectionScreenState();
// }
//
// class _FaceDetectionScreenState extends State<FaceDetectionScreen> {
//   late FaceDetector _detector;
//   ui.Image? _displayImage;
//   List<Rect> _faces = [];
//   bool _isLoading = true;
//   String _status = 'Initializing...';
//   img.Image? _originalImage;
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeDetector();
//   }
//
//   Future<void> _initializeDetector() async {
//     try {
//       _detector = FaceDetector();
//       await _detector.loadModel();
//       await _loadAndProcessImage();
//       //setState(() => _isLoading = false);
//     } catch (e) {
//       setState(() {
//         _status = 'Error: ${e.toString()}';
//         _isLoading = false;
//       });
//     }
//   }
//
//   Future<void> _loadAndProcessImage() async {
//     try {
//       final byteData = await rootBundle.load('assets/images/im.jpg');
//       _originalImage = img.decodeImage(byteData.buffer.asUint8List());
//
//       if (_originalImage == null) throw Exception('Failed to decode image');
//
//       final faces = await _detector.detectFaces(_originalImage!);
//       final displayImage = await _convertImageToUi(_originalImage!);
//
//       setState(() {
//         _displayImage = displayImage;
//         _faces = faces;
//       });
//     } catch (e) {
//       setState(() => _status = 'Processing error: ${e.toString()}');
//       print('Processing error: ${e.toString()}');
//       _isLoading = false;
//     }
//   }
//
//   Future<ui.Image> _convertImageToUi(img.Image image) async {
//     final pngBytes = Uint8List.fromList(img.encodePng(image));
//     final codec = await ui.instantiateImageCodec(pngBytes);
//     final frame = await codec.getNextFrame();
//     return frame.image;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('UltraFace Detection')),
//       body: _isLoading
//           ? _buildLoading()
//           : _buildDetectionResult(),
//     );
//   }
//
//   Widget _buildLoading() {
//     return Center(
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const CircularProgressIndicator(),
//           const SizedBox(height: 20),
//           Text(_status),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildDetectionResult() {
//     if (_displayImage == null || _originalImage == null) {
//       return const Center(child: Text('No image loaded'));
//     }
//
//     final aspectRatio = _originalImage!.width / _originalImage!.height;
//     final screenWidth = MediaQuery.of(context).size.width;
//     final renderHeight = screenWidth / aspectRatio;
//
//     return Stack(
//       children: [
//     Center(
//     child: Column(
//       children: [
//         CustomPaint(
//         painter: ImagePainter(
//           _displayImage!,
//           renderSize: Size(screenWidth, renderHeight),
//         ),
//         ),
//         CustomPaint(
//           painter: FacePainter(
//             _faces,
//             originalSize: Size(
//               _originalImage!.width.toDouble(),
//               _originalImage!.height.toDouble(),
//             ),
//             renderSize: Size(screenWidth, renderHeight),
//           ),
//         ),
//       ],
//     ),
//
//     )
//     ],
//     );
//     }
//
//   @override
//   void dispose() {
//     _detector.dispose();
//     super.dispose();
//   }
// }
//
// class FaceDetector {
//   late Interpreter _interpreter;
//   static const inputSize = 320;
//
//   Future<void> loadModel() async {
//     const channels = 3;
//     const height = 240;
//     const width = 320;
//     try {
//       _interpreter = await Interpreter.fromAsset('assets/models/model_fixed.tflite');
//      /// _interpreter.resizeInputTensor(0, [1, height, width, channels]);
//       _interpreter.allocateTensors();
//       print("Model loaded successfully");
//       final inputTensor = _interpreter.getInputTensor(0);
//       print("Model expects input shape: ${inputTensor.shape}");
//       print('Model expects input type: ${inputTensor.type}');
//       print('Tensors allocated successfully');
//
//
//
//     } catch (e) {
//       throw Exception('Failed to load model: ${e.toString()}');
//     }
//   }
//
//   Future<List<Rect>> detectFaces(img.Image image) async {
//     final input = _preprocessImage2(image); // Your preprocessed NCHW tensor
//
//     // Get tensor details
//     final inputTensor = _interpreter.getInputTensor(0);
//     final outputScoresTensor = _interpreter.getOutputTensor(0);
//     final outputBoxesTensor = _interpreter.getOutputTensor(1);
//
//     print('Input details: ${inputTensor.shape} ${inputTensor.type}');
//     print('Scores shape: ${outputScoresTensor.shape}');
//     print('Boxes shape: ${outputBoxesTensor.shape}');
//
//     // Create output buffers with explicit sizes
//     final scores = List<double>.filled(
//         outputScoresTensor.shape.reduce((a, b) => a * b),
//         0.0
//     );
//
//     final boxes = List<double>.filled(
//         outputBoxesTensor.shape.reduce((a, b) => a * b),
//         0.0
//     );
//
//     // Run with actual preprocessed input
//     _interpreter.run([input], [scores, boxes]);
//
//     return _postProcess(scores, boxes, image.width, image.height);
//   }
//
//
//   Float32List _preprocessImage(img.Image image) {
//     const channels = 3;
//     const height = 240;
//     const width = 320;
//
//     final resized = img.copyResize(image, width: width, height: height);
//     final input = Float32List(1*channels * height * width); // Fix: 3 × 240 × 320
//
//     // Channel-first layout (NCHW)
//     int pixelIndex = 0;
//     for (int y = 0; y < height; y++) {
//       for (int x = 0; x < width; x++) {
//         final pixel = resized.getPixel(x, y);
//         // Assign RGB values to their respective channels
//         input[pixelIndex] = pixel.r / 255.0;     // Red channel
//         input[pixelIndex + height * width] = pixel.g / 255.0; // Green channel
//         input[pixelIndex + 2 * height * width] = pixel.b / 255.0; // Blue channel
//         pixelIndex++;
//       }
//     }
//
//     return input;
//   }
//
//   Float32List _preprocessImage2(img.Image image) {
//     const channels = 3;
//     const height = 240;
//     const width = 320;
//
//     final resized = img.copyResize(image, width: width, height: height);
//     final input = Float32List(1 * height * width * channels); // NHWC
//
//     int index = 0;
//     for (int y = 0; y < height; y++) {
//       for (int x = 0; x < width; x++) {
//         final pixel = resized.getPixel(x, y);
//         // NHWC layout: [1, 240, 320, 3]
//         input[index++] = pixel.r / 255.0; // Red
//         input[index++] = pixel.g / 255.0; // Green
//         input[index++] = pixel.b / 255.0; // Blue
//       }
//     }
//
//     return input;
//   }
//
//   List<Rect> _postProcess(
//       List<double> scores,
//       List<double> boxes,
//       int imgWidth,
//       int imgHeight,
//       ) {
//     final faces = <Rect>[];
//     const threshold = 0.7;
//
//     for (int i = 0; i < 4420; i++) {
//       final confidence = scores[i * 2 + 1];
//       if (confidence > threshold) {
//         final boxIndex = i * 4;
//         final x1 = boxes[boxIndex] * imgWidth;
//         final y1 = boxes[boxIndex + 1] * imgHeight;
//         final x2 = boxes[boxIndex + 2] * imgWidth;
//         final y2 = boxes[boxIndex + 3] * imgHeight;
//
//         faces.add(Rect.fromLTRB(
//           x1.clamp(0, imgWidth.toDouble()),
//           y1.clamp(0, imgHeight.toDouble()),
//           x2.clamp(0, imgWidth.toDouble()),
//           y2.clamp(0, imgHeight.toDouble()),
//         ));
//       }
//     }
//     return _nonMaxSuppression(faces);
//   }
//
//   List<Rect> _nonMaxSuppression(List<Rect> candidates) {
//     candidates.sort((a, b) => b.width.compareTo(a.width));
//     final selected = <Rect>[];
//
//     while (candidates.isNotEmpty) {
//       final current = candidates.removeAt(0);
//       selected.add(current);
//       candidates.removeWhere((rect) => _iou(current, rect) > 0.3);
//     }
//
//     return selected;
//   }
//
//   double _iou(Rect a, Rect b) {
//     final intersection = a.intersect(b);
//     if (intersection.isEmpty) return 0;
//
//     final areaA = a.width * a.height;
//     final areaB = b.width * b.height;
//     final union = areaA + areaB - (intersection.width * intersection.height);
//
//     return (intersection.width * intersection.height) / union;
//   }
//
//   void dispose() {
//     _interpreter.close();
//   }
// }
//
// class ImagePainter extends CustomPainter {
//   final ui.Image image;
//   final Size renderSize;
//
//   ImagePainter(this.image, {required this.renderSize});
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final src = Rect.fromLTRB(0, 0, image.width.toDouble(), image.height.toDouble());
//     final dst = Rect.fromCenter(
//       center: size.center(Offset.zero),
//       width: renderSize.width,
//       height: renderSize.height,
//     );
//     canvas.drawImageRect(image, src, dst, Paint());
//   }
//
//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) => false;
// }
//
// class FacePainter extends CustomPainter {
//   final List<Rect> faces;
//   final Size originalSize;
//   final Size renderSize;
//   final Paint paint1 = Paint()
//     ..color = Colors.red
//     ..style = PaintingStyle.stroke
//     ..strokeWidth = 2;
//
//   FacePainter(this.faces, {required this.originalSize, required this.renderSize});
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final scaleX = renderSize.width / originalSize.width;
//     final scaleY = renderSize.height / originalSize.height;
//
//     for (final rect in faces) {
//       final scaledRect = Rect.fromLTRB(
//         rect.left * scaleX,
//         rect.top * scaleY,
//         rect.right * scaleX,
//         rect.bottom * scaleY,
//       ).translate(
//         (size.width - renderSize.width) / 2,
//         (size.height - renderSize.height) / 2,
//       );
//
//       canvas.drawRect(scaledRect, paint1);
//     }
//   }
//
//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) => true;
// }