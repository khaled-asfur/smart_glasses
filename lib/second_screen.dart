// import 'dart:io';
// import 'dart:typed_data';
// import 'dart:math' as math;
// import 'package:flutter/material.dart';
// import 'package:tflite_flutter/tflite_flutter.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:image/image.dart' as img;
//
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
//   // Change these as needed per your BlazeFace model’s expected input size.
//   final int _inputWidth = 128;
//   final int _inputHeight = 128;
//   final int _inputChannels = 3;
//
//   @override
//   void initState() {
//     super.initState();
//     loadModel();
//   }
//
//   /// Loads the TFLite model from assets.
//   Future<void> loadModel() async {
//     try {
//       _interpreter = await Interpreter.fromAsset('assets/models/blazeface_model.tflite');
//       print('Model loaded successfully.');
//     } catch (e) {
//       print('Error loading model: $e');
//     }
//   }
//
//   /// Uses image_picker to select an image from the gallery.
//   Future<void> pickImage() async {
//     final picker = ImagePicker();
//     final XFile? pickedImage =
//     await picker.pickImage(source: ImageSource.gallery);
//     if (pickedImage != null) {
//       setState(() {
//         _imageFile = File(pickedImage.path);
//         _resultText = 'Processing image...';
//       });
//       await runFaceDetection(_imageFile!);
//     }
//   }
//
//   /// Preprocesses the image, runs inference, and processes output.
//   Future<void> runFaceDetection(File imageFile) async {
//     if (_interpreter == null) {
//       setState(() {
//         _resultText = 'Model not loaded';
//       });
//       return;
//     }
//
//     // Read the image file as bytes.
//     final imageBytes = await imageFile.readAsBytes();
//
//     // Decode the image using the image package.
//     img.Image? imageInput = img.decodeImage(imageBytes);
//     if (imageInput == null) {
//       setState(() {
//         _resultText = 'Error decoding image';
//       });
//       return;
//     }
//
//     // Resize image to model's input size.
//     img.Image resizedImage =
//     img.copyResize(imageInput, width: _inputWidth, height: _inputHeight);
//
//     // Convert image to a Float32List normalized to [0, 1].
//     Float32List input = imageToFloat32List(resizedImage);
//
//     // Prepare the input tensor shape [1, height, width, channels].
//     var inputShape = [_inputHeight, _inputWidth, _inputChannels];
//     // Some models expect a 4D tensor. Create a 4D buffer with batch size 1.
//     var inputBuffer = input.buffer.asFloat32List();
//
//     // Prepare output buffer.
//     // The output shape and type depend on your model.
//     // Here, we use a placeholder output shape. Adjust accordingly.
//     // For example, if your model outputs 10 values:
//     var outputShape = [1, 10];
//     var outputBuffer = List.filled(1 * 10, 0.0).reshape(outputShape);
//
//     // Run inference.
//     try {
//       _interpreter!.run(inputBuffer, outputBuffer);
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
//   /// Converts an image (from the image package) to a Float32List normalized to [0, 1].
//   Float32List imageToFloat32List(img.Image image) {
//     // Create a list to hold normalized pixel values.
//     var convertedBytes = Float32List(_inputWidth * _inputHeight * _inputChannels);
//     int pixelIndex = 0;
//
//     for (int y = 0; y < _inputHeight; y++) {
//       // for (int x = 0; x < _inputWidth; x++) {
//       //   int pixel = image.getPixel(x, y);
//       //   // The image package returns pixels as 32-bit integers in ARGB format.
//       //   // Extract red, green, blue components.
//       //   double r = img.getRed(pixel) / 255.0;
//       //   double g = img.getGreen(pixel) / 255.0;
//       //   double b = img.getBlue(pixel) / 255.0;
//       //   convertedBytes[pixelIndex++] = r;
//       //   convertedBytes[pixelIndex++] = g;
//       //   convertedBytes[pixelIndex++] = b;
//       // }
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
//       appBar: AppBar(
//         title: Text('BlazeFace Face Detection'),
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             SizedBox(height: 20),
//             _imageFile != null
//                 ? Image.file(_imageFile!)
//                 : Container(
//               height: 200,
//               width: 200,
//               color: Colors.grey[300],
//               child: Center(child: Text('No image selected')),
//             ),
//             SizedBox(height: 20),
//             Text(
//               _resultText,
//               textAlign: TextAlign.center,
//             ),
//             SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: pickImage,
//               child: Text('Pick Image from Gallery'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// //
// // class SecondScreen extends StatefulWidget {
// //   const SecondScreen({super.key});
// //
// //   @override
// //   SecondScreenState createState() => SecondScreenState();
// // }
// //
// // class SecondScreenState extends State<SecondScreen> {
// //   // Controller to retrieve the text from the TextField.
// //   final TextEditingController _textController = TextEditingController();
// //
// //   @override
// //   void dispose() {
// //     // Dispose the controller when the widget is removed from the widget tree.
// //     _textController.dispose();
// //     super.dispose();
// //   }
// //
// //   void _onButtonPressed() {
// //     // Example action when the button is pressed.
// //     // For example, print the content of the TextField.
// //     print('Text entered: ${_textController.text}');
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       SnackBar(content: Text('You entered: ${_textController.text}')),
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text('Second Screen'),
// //       ),
// //       body: SingleChildScrollView(
// //         // Use SingleChildScrollView in case content overflows on smaller screens.
// //         child: Padding(
// //           padding: const EdgeInsets.all(16.0),
// //           child: Column(
// //             children: [
// //               // Display an image from the network.
// //               Image.network(
// //                 'https://via.placeholder.com/300.png',
// //                 height: 200,
// //                 width: double.infinity,
// //                 fit: BoxFit.cover,
// //               ),
// //               const SizedBox(height: 20),
// //               // A text field to accept user input.
// //               TextField(
// //                 controller: _textController,
// //                 decoration: InputDecoration(
// //                   labelText: 'Enter some text',
// //                   border: OutlineInputBorder(),
// //                 ),
// //               ),
// //               const SizedBox(height: 20),
// //               // A button that performs an action.
// //               ElevatedButton(
// //                 child: Text('Submit'),
// //                 onPressed: _onButtonPressed,
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }