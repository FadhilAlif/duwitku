import 'package:flutter/material.dart';

class CameraBottomControlsWidget extends StatelessWidget {
  final VoidCallback onCapture;
  final VoidCallback onSwitchCamera;
  final VoidCallback onPickFromGallery;
  final bool isLoading;

  const CameraBottomControlsWidget({
    super.key,
    required this.onCapture,
    required this.onSwitchCamera,
    required this.onPickFromGallery,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Gallery button
            IconButton(
              onPressed: isLoading ? null : onPickFromGallery,
              icon: const Icon(Icons.photo_library),
              iconSize: 32,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                disabledBackgroundColor: Colors.grey,
              ),
            ),
            // Capture button
            GestureDetector(
              onTap: isLoading ? null : onCapture,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.black87, width: 4),
                ),
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(strokeWidth: 3),
                      )
                    : null,
              ),
            ),
            // Switch camera button
            IconButton(
              onPressed: isLoading ? null : onSwitchCamera,
              icon: const Icon(Icons.cameraswitch),
              iconSize: 32,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                disabledBackgroundColor: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
