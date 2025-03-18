import 'package:flutter/material.dart';
import 'package:smart_glasses/Face_detection_screen.dart';
import 'package:smart_glasses/bridge_mobile.dart';
import 'package:smart_glasses/yolo_face_detection_draw_dots.dart';

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
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Smart Glasses')),
      body: Column(
        children: [
          ElevatedButton(
            child: Text('Go to detection Screen'),
            onPressed: () {
              // Navigate to the SecondScreen when the button is pressed.
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => FaceDetectionScreen()),
              );
            },
          ),
          ElevatedButton(
            child: Text('Go to bridge mobile Screen'),
            onPressed: () {
              // Navigate to the SecondScreen when the button is pressed.
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => WebSocketHandler()),
              );
            },
          ),
        ],
      ),
    );
  }
}
