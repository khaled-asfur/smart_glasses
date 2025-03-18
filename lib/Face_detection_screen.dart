import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smart_glasses/google_ml_kit_detection.dart';

class FaceDetectionScreen extends StatefulWidget {
  @override
  _FaceDetectionScreenState createState() => _FaceDetectionScreenState();
}

class _FaceDetectionScreenState extends State<FaceDetectionScreen> {
  final FaceDetectorService _faceDetectorService = FaceDetectorService();
  ui.Image? _image;
  List<Face>? _faces;

  @override
  void initState() {
    super.initState();
    _loadImageAndDetectFaces();
  }

  Future<File> _writeBytesToFile(Uint8List bytes) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/temp_face.jpg');
    return file.writeAsBytes(bytes, flush: true);
  }

  /// Load image from assets, write to a temporary file, and detect faces
  Future<void> _loadImageAndDetectFaces() async {
    // Load asset bytes
    final ByteData data = await rootBundle.load('assets/images/img.jpg');
    final Uint8List bytes = data.buffer.asUint8List();

    // Decode the image for display
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    setState(() {
      _image = frameInfo.image;
    });

    // Write bytes to a temporary file for face detection
    final File tempFile = await _writeBytesToFile(bytes);

    // Use the existing service to detect faces
    final faces = await _faceDetectorService.detectFaces(tempFile);
    setState(() {
      _faces = faces;
    });
  }

  @override
  void dispose() {
    _faceDetectorService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Face Detection')),
      body: Center(
        child: _image == null
            ? CircularProgressIndicator()
            : CustomPaint(
          painter: FacePainter(_image!, _faces),
          child: SizedBox(
            width: _image!.width.toDouble(),
            height: _image!.height.toDouble(),
          ),
        ),
      ),
    );
  }
}

/// Custom Painter to draw bounding boxes around detected faces
class FacePainter extends CustomPainter {
  final ui.Image image;
  final List<Face>? faces;

  FacePainter(this.image, this.faces);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.red
      ..strokeWidth = 3.0;

    // Draw the original image
    canvas.drawImage(image, Offset.zero, Paint());

    // Draw bounding boxes around detected faces
    if (faces != null) {
      for (Face face in faces!) {
        canvas.drawRect(face.boundingBox, paint);
      }
    }
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) {
    return oldDelegate.faces != faces;
  }
}
