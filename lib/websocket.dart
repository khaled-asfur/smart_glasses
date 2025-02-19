// import 'dart:convert';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:path_provider/path_provider.dart';
// import 'dart:io';
//
// class WebSocketImpl extends StatefulWidget {
//   @override
//   _WebSocketImplState createState() => _WebSocketImplState();
// }
//
// class _WebSocketImplState extends State<WebSocketImpl> {
//   final String serverUrl = 'ws://<laptop_ip>:8080'; // Replace <laptop_ip> with your laptop's IP
//   late WebSocketChannel channel;
//   Uint8List? imageBytes;
//
//   @override
//   void initState() {
//     super.initState();
//     channel = WebSocketChannel.connect(Uri.parse(serverUrl));
//
//     channel.stream.listen((message) async {
//       try {
//         // Decode Base64 image
//         final decodedBytes = base64Decode(message);
//         setState(() {
//           imageBytes = decodedBytes;
//         });
//
//         // Save the image to the local storage
//         final appDir = await getApplicationDocumentsDirectory();
//         final filePath = '${appDir.path}/received_image.jpg';
//         final file = File(filePath);
//         await file.writeAsBytes(decodedBytes);
//         print('Image saved to: $filePath');
//       } catch (e) {
//         print('Error processing image: $e');
//       }
//     }, onError: (error) {
//       print('WebSocket error: $error');
//     }, onDone: () {
//       print('WebSocket connection closed');
//     });
//   }
//
//   @override
//   void dispose() {
//     channel.sink.close();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(title: Text('WebSocket Image Receiver')),
//         body: Center(
//           child: imageBytes != null
//               ? Image.memory(imageBytes!)
//               : Text('Waiting for image...'),
//         ),
//       ),
//     );
//   }
// }
//
// void main() {
//   runApp(WebSocketImpl());
// }
