import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
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

  /// Load image from gallery, decode it for display, and detect faces.
  Future<void> _loadImageAndDetectFaces() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
    await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return; // No image selected

    final File imageFile = File(pickedFile.path);
    final Uint8List bytes = await imageFile.readAsBytes();

    // Decode the image for display
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    setState(() {
      _image = frameInfo.image;
    });

    // Use the existing service to detect faces
    final faces = await _faceDetectorService.detectFaces(imageFile);
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
            : FittedBox(
          fit: BoxFit.contain,
          child: CustomPaint(
            painter: FacePainter(_image!, _faces),
            child: SizedBox(
              width: _image!.width.toDouble(),
              height: _image!.height.toDouble(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom Painter to draw bounding boxes around detected faces.
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

    // Draw the original image.
    canvas.drawImage(image, Offset.zero, Paint());

    // Draw bounding boxes around detected faces.
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
