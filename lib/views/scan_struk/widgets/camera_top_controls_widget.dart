import 'package:flutter/material.dart';

class CameraTopControlsWidget extends StatelessWidget {
  final bool isFlashOn;
  final VoidCallback onFlashToggle;
  final VoidCallback onClose;

  const CameraTopControlsWidget({
    super.key,
    required this.isFlashOn,
    required this.onFlashToggle,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
                foregroundColor: Colors.white,
              ),
            ),
            IconButton(
              onPressed: onFlashToggle,
              icon: Icon(isFlashOn ? Icons.flash_on : Icons.flash_off),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
