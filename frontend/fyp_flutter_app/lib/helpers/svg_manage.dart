import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

Future<BitmapDescriptor> svgToBitmapDescriptor(String assetPath, {Size size = const Size(48, 48)}) async {
  // Load the SVG string from assets
  final String svgString = await rootBundle.loadString(assetPath);
  // Parse the SVG and create a PictureInfo object
  final DrawableRoot svgDrawable = await svg.fromSvgString(svgString, null);
  // Calculate the size based on device pixel ratio
  final double devicePixelRatio = ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
  final int width = (size.width * devicePixelRatio).toInt();
  final int height = (size.height * devicePixelRatio).toInt();
  // Render the SVG to a PictureRecorder
  final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(pictureRecorder);
  canvas.scale(devicePixelRatio);
  svgDrawable.draw(canvas, Rect.fromLTWH(0, 0, size.width, size.height));
  // Convert the Picture to an Image
  final ui.Image image = await pictureRecorder.endRecording().toImage(width, height);
  // Convert the Image to ByteData and then Uint8List
  final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
}