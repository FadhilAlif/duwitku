import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../controllers/camera_controller.dart';
import 'widgets/camera_preview_widget.dart';
import 'widgets/camera_top_controls_widget.dart';
import 'widgets/camera_bottom_controls_widget.dart';
import 'widgets/camera_permission_widget.dart';
import 'widgets/camera_error_widget.dart';
import 'preview_screen.dart';

class ScanStrukScreen extends StatefulWidget {
  const ScanStrukScreen({super.key});

  @override
  State<ScanStrukScreen> createState() => _ScanStrukScreenState();
}

class _ScanStrukScreenState extends State<ScanStrukScreen> {
  late CameraNotifier _cameraNotifier;

  @override
  void initState() {
    super.initState();
    _cameraNotifier = CameraNotifier();
    _cameraNotifier.addListener(_onCameraStateChanged);
    _initializeCamera();
  }

  void _onCameraStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initializeCamera() async {
    await _cameraNotifier.initializeCamera();
  }

  Future<void> _handleCapture() async {
    final imagePath = await _cameraNotifier.takePicture();
    if (imagePath != null && mounted) {
      _navigateToPreview(imagePath);
    }
  }

  Future<void> _handlePickFromGallery() async {
    final imagePath = await _cameraNotifier.pickImageFromGallery();
    if (imagePath != null && mounted) {
      _navigateToPreview(imagePath);
    }
  }

  void _navigateToPreview(String imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreviewScreen(imagePath: imagePath),
      ),
    );
  }

  Future<void> _handlePermissionRequest() async {
    final state = _cameraNotifier.state;
    if (state.isPermanentlyDenied) {
      await openAppSettings();
    } else {
      await _initializeCamera();
    }
  }

  @override
  void dispose() {
    _cameraNotifier.removeListener(_onCameraStateChanged);
    _cameraNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _cameraNotifier.state;
    final cameraController = _cameraNotifier.cameraController;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview or Status Screens
          if (state.isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          else if (!state.hasPermission)
            CameraPermissionWidget(
              isPermanentlyDenied: state.isPermanentlyDenied,
              onRequestPermission: _handlePermissionRequest,
            )
          else if (state.errorMessage != null && !state.isInitialized)
            CameraErrorWidget(
              errorMessage: state.errorMessage!,
              onRetry: _initializeCamera,
            )
          else if (state.isInitialized && cameraController != null)
            CameraPreviewWidget(cameraController: cameraController)
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // Top Controls
          if (state.isInitialized && cameraController != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: CameraTopControlsWidget(
                isFlashOn: state.isFlashOn,
                onFlashToggle: _cameraNotifier.toggleFlash,
                onClose: () => Navigator.pop(context),
              ),
            ),

          // Bottom Controls
          if (state.isInitialized && cameraController != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: CameraBottomControlsWidget(
                onCapture: _handleCapture,
                onSwitchCamera: _cameraNotifier.switchCamera,
                onPickFromGallery: _handlePickFromGallery,
                isLoading: state.isLoading,
              ),
            ),

          // Error Snackbar
          if (state.errorMessage != null && state.isInitialized)
            Positioned(
              bottom: 150,
              left: 16,
              right: 16,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          state.errorMessage!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _cameraNotifier.clearError,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
