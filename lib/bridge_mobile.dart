import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: WebSocketHandler(),
    );
  }
}

class WebSocketHandler extends StatefulWidget {
  @override
  _WebSocketHandlerState createState() => _WebSocketHandlerState();
}

class _WebSocketHandlerState extends State<WebSocketHandler> {
  late IOWebSocketChannel serverChannel;
  HttpServer? glassesServer;
  String ipAddress = "";
  String connectionStatus = "Disconnected";
  Map<WebSocket, WebSocket> socketConnections = {};

  @override
  void initState() {
    super.initState();
    startGlassesServer(); // Start the WebSocket server for smart glasses
    connectToServer(); // Connect to the main server
    _findLocalIpAddress();
  }

  // Starts a WebSocket server to communicate with smart glasses
  void startGlassesServer() async {
    try {
      glassesServer = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
      setState(() {
        connectionStatus = "Glasses Server Running";
      });
      glassesServer!.listen((HttpRequest request) async {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          WebSocket socket = await WebSocketTransformer.upgrade(request);
          socket.listen(
                (data) {
              print('Image received from the smart glasses');
              handleGlassesMessage(data, socket);
            },
            onDone: () {
              print('Smart glasses disconnected');
              socketConnections.remove(socket);
            },
            onError: (error) {
              print('Error from smart glasses: $error');
              socketConnections.remove(socket);
            },
          );
          socketConnections[socket] = socket;
        }
      });
    } catch (e) {
      print('Failed to start glasses server: $e');
      setState(() {
        connectionStatus = "Failed to start glasses server";
      });
    }
  }

  // Establishes a WebSocket connection to the main server
  void connectToServer() {
    try {
      serverChannel = IOWebSocketChannel.connect('ws://192.168.2.238:8082/ws/image');
      setState(() {
        connectionStatus = "Connected to main server";
      });
      print("Connected to main server");
      serverChannel.stream.listen(
            (data) {
          print('Response received from the server');
          handleServerMessage(data);
        },
        onError: (error) {
          print('Error from main server: $error');
          setState(() {
            connectionStatus = "Disconnected from main server";
          });
          // Attempt to reconnect
          Future.delayed(Duration(seconds: 5), () {
            connectToServer();
          });
        },
        onDone: () {
          print('Connection to main server closed');
          setState(() {
            connectionStatus = "Disconnected from main server";
          });
          // Attempt to reconnect
          Future.delayed(Duration(seconds: 5), () {
            connectToServer();
          });
        },
      );
    } catch (e) {
      print('Failed to connect to main server: $e');
      setState(() {
        connectionStatus = "Failed to connect to main server";
      });
      // Attempt to reconnect
      Future.delayed(Duration(seconds: 5), () {
        connectToServer();
      });
    }
  }

  // Handles messages received from smart glasses
  void handleGlassesMessage(dynamic data, WebSocket socket) {
    try {
      sendImageToServer(data);
    } catch (e) {
      print('Error handling glasses message: $e');
    }
  }

  // Sends the received image to the main server for processing
  void sendImageToServer(dynamic data) {
    try {
      serverChannel.sink.add(jsonEncode('{"image":"lool"}'));
      print('Image sent to the server');
    } catch (e) {
      print('Error sending image to server: $e');
    }
  }

  // Handles messages received from the main server and forwards them to smart glasses
  void handleServerMessage(dynamic data) {
    for (var socket in socketConnections.values) {
      try {
        socket.add(data); // Send processed data back to the smart glasses
      } catch (e) {
        print('Error sending data to smart glasses: $e');
      }
    }
  }

  @override
  void dispose() {
    serverChannel.sink.close(); // Close the connection to the main server
    glassesServer?.close(); // Shut down the smart glasses server
    socketConnections.clear(); // Clear all WebSocket connections
    super.dispose();
  }

  void _findLocalIpAddress() async {
    try {
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
    } catch (e) {
      print('Error finding local IP address: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('WebSocket Bridge')),
      body: Center(
        child: Column(
          children: [
            Text('Running WebSocket Server for Smart Glasses'),
            Text('This device\'s IP address is $ipAddress',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Status: $connectionStatus',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            ElevatedButton(
              onPressed: () => sendImageToServer('{"image":"lool"}'),
              child: Text("Send image to server"),
            ),
          ],
        ),
      ),
    );
  }
}