// import 'dart:io';
//
// import 'package:shelf/shelf.dart';
// import 'package:shelf/shelf_io.dart' as shelf_io;
// import 'package:shelf_router/shelf_router.dart' as shelf_router;
//
// void runHttpLocalServer() async {
//   final app = shelf_router.Router();
//
//   // Endpoint to receive the image
//   app.post('/upload', (Request request) async {
//     // Get the image data from the request body
//     final contentType = request.headers['Content-Type'] ?? '';
//     if (!contentType.startsWith('multipart/form-data')) {
//       return Response.badRequest(body: 'Invalid content type');
//     }
//
//     final body = await request.read().toList();
//     final imageBytes = body.expand((bytes) => bytes).toList();
//
//     // Save the image to a file (optional)
//     final fileName =
//         'received_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
//     final file = File(fileName);
//     await file.writeAsBytes(imageBytes);
//
//     print('Image received and saved as $fileName');
//     return Response.ok('Image received successfully');
//   });
//
//   // Start the server on a local IP and port
//   final ip = InternetAddress.anyIPv4;
//   const port = 8080;
//
//   final server = await shelf_io.serve(app, ip, port);
//   print('HTTP server running on http://${server.address.host}:${server.port}');
// }
