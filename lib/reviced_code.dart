// import 'dart:io';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:tflite_flutter/tflite_flutter.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:image/image.dart' as img;
//
// class FaceDetectionScreen extends StatefulWidget {
//   @override
//   _FaceDetectionScreenState createState() => _FaceDetectionScreenState();
// }
//
// class _FaceDetectionScreenState extends State<FaceDetectionScreen> {
//   Interpreter? _interpreter;
//   File? _imageFile;
//   String _resultText = 'No result yet';
//
//   // Expected input size for the model.
//   final int _inputWidth = 200;
//   final int _inputHeight = 200;
//   final int _inputChannels = 3;
//
//   @override
//   void initState() {
//     super.initState();
//     loadModel();
//   }
//
//   Future<void> loadModel() async {
//     try {
//       _interpreter = await Interpreter.fromAsset('assets/models/blazeface_model.tflite');
//       print('Model loaded successfully');
//     } catch (e) {
//       print('Error loading model: $e');
//     }
//   }
//
//   Future<void> pickImage() async {
//     final picker = ImagePicker();
//     final pickedFile = await picker.pickImage(source: ImageSource.gallery);
//     if (pickedFile != null) {
//       setState(() {
//         _imageFile = File(pickedFile.path);
//         _resultText = 'Processing image...';
//       });
//       await runFaceDetection(_imageFile!);
//     }
//   }
//
//   Future<void> runFaceDetection(File imageFile) async {
//     if (_interpreter == null) {
//       setState(() {
//         _resultText = 'Model not loaded';
//       });
//       return;
//     }
//
//     // Read and decode image.
//     final imageBytes = await imageFile.readAsBytes();
//     img.Image? imageInput = img.decodeImage(imageBytes);
//     if (imageInput == null) {
//       setState(() {
//         _resultText = 'Error decoding image';
//       });
//       return;
//     }
//
//     // Resize image to model input size.
//     img.Image resizedImage = img.copyResize(imageInput, width: _inputWidth, height: _inputHeight);
//
//     // Prepare input tensor.
//     Float32List input = imageToFloat32List(resizedImage, _inputWidth, _inputHeight);
//
//     // Allocate output tensor based on the model's expected output.
//     // Here, we assume output is of shape [1, 10] (adjust based on your model).
//     var outputShape = [1, 10];
//     var outputBuffer = List.filled(1 * 10, 0.0).reshape(outputShape);
//
//     try {
//       _interpreter!.run(input, outputBuffer);
//       setState(() {
//         _resultText = 'Output: $outputBuffer';
//       });
//     } catch (e) {
//       setState(() {
//         _resultText = 'Error during inference: $e';
//       });
//     }
//   }
//
//
//   Float32List imageToFloat32List(img.Image image, int inputWidth, int inputHeight) {
//     // Define the number of color channels (RGB)
//     const int channels = 3;
//     // Create a Float32List with the required length
//     Float32List convertedBytes = Float32List(inputWidth * inputHeight * channels);
//     int pixelIndex = 0;
//
//     for (int y = 0; y < inputHeight; y++) {
//       for (int x = 0; x < inputWidth; x++) {
//         // getPixel now returns a Pixel object.
//         var pixel = image.getPixel(x, y);
//         // Access the red, green, and blue properties of the Pixel object.
//         double r = pixel.r / 255.0;
//         double g = pixel.g / 255.0;
//         double b = pixel.b / 255.0;
//
//         convertedBytes[pixelIndex++] = r;
//         convertedBytes[pixelIndex++] = g;
//         convertedBytes[pixelIndex++] = b;
//       }
//     }
//     return convertedBytes;
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
//       appBar: AppBar(title: Text('BlazeFace Detection')),
//       body: Column(
//         children: [
//           ElevatedButton(
//             onPressed: pickImage,
//             child: Text('Pick Image'),
//           ),
//           _imageFile != null ? Image.file(_imageFile!) : Container(),
//           Text(_resultText),
//         ],
//       ),
//     );
//   }
// }
