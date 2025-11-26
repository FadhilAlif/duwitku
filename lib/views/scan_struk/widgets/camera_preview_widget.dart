import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraPreviewWidget extends StatelessWidget {
  final CameraController cameraController;

  const CameraPreviewWidget({super.key, required this.cameraController});

  @override
  Widget build(BuildContext context) {
    if (!cameraController.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    // Simple preview without zoom - let CameraPreview handle aspect ratio naturally
    return CameraPreview(cameraController);
  }
}
