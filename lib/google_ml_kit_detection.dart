import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectorService {
  late final FaceDetector _faceDetector;

  FaceDetectorService() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true, // Enable face contours (optional)
        enableLandmarks: true, // Enable facial landmarks
        enableClassification: true, // Smiling & Eye Open Probability
        enableTracking: true, // Track faces across frames
      ),
    );
  }

  /// Detects faces in an image file.
  Future<List<Face>> detectFaces(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final List<Face> faces = await _faceDetector.processImage(inputImage);
    return faces;
  }

  void dispose() {
    _faceDetector.close();
  }
}
