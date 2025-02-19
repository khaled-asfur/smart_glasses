import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:smart_glasses/assets_face_detection_deep.dart';
import 'package:smart_glasses/yolo_face_detection.dart';
// import 'package:smart_glasses/assets_face_detection.dart';

import 'dart:math' as math;
// import 'package:tflite_flutter/tflite_flutter.dart';
// import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

//import 'package:smart_glasses/reviced_code.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WebSocket Server',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  HttpServer? _server;
  final List<WebSocket> _clients = [];
  final List<Uint8List> _images = [];
  String ipAddress="";

  @override
  void initState() {
    super.initState();
    _startServer();
    _findLocalIpAddress();
  }

  void _findLocalIpAddress() async {
    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4) {
          print('Local IP Address: ${addr.address}');
          setState(() {
            ipAddress = addr.address;
          });
        }
      }
    }
  }

  Future<void> _startServer() async {
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
      print('WebSocket server is running on ws://${_server!.address.address}:${_server!.port}');

      _server!.listen((HttpRequest request) async {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          WebSocket socket = await WebSocketTransformer.upgrade(request);
          _handleNewClient(socket);
        } else {
          request.response
            ..statusCode = HttpStatus.forbidden
            ..write('WebSocket connections only.')
            ..close();
        }
      });
    } catch (e) {
      print('Failed to start WebSocket server: $e');
    }
  }

  void _handleNewClient(WebSocket socket) {
    print('New client connected.');
    _clients.add(socket);

    socket.listen((data) {
      _onMessageReceived(data);
    }, onDone: () {
      _clients.remove(socket);
      print('Client disconnected.');
    });
  }

  void _onMessageReceived(dynamic message) {
    // Check if the message is a Base64-encoded image
    if (message is String) {
      try {
        // Attempt to decode the Base64 message to bytes
        Uint8List imageData = base64Decode(message);
        print('Image received and decoded.');

        // Add the image data to the list
        setState(() {
          _images.add(imageData);
        });
      } catch (e) {
        print('Failed to decode image: $e');
      }
    } else {
      print('Received non-image message: $message');
    }
  }

  @override
  void dispose() {
    _server?.close(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('WebSocket Server')),
      body: Column(
        children: [
          ElevatedButton(
            child: Text('Go to Second Screen'),
            onPressed: () {
              // Navigate to the SecondScreen when the button is pressed.
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FaceRecognitionScreen()),
              );
            },
          ),
          const Text('WebSocket Server running on port 8080', style: TextStyle(fontWeight: FontWeight.bold)),
           Text('This device\'s IP address is $ipAddress', style:  const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: ListView.builder(
              itemCount: _images.length,
              itemBuilder: (context, index) => ListTile(
                title: Image.memory(_images[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
