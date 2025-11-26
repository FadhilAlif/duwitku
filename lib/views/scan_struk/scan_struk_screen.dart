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

class _ScanStrukScreenState extends State<ScanStrukScreen>
    with WidgetsBindingObserver {
  late CameraNotifier _cameraNotifier;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cameraNotifier = CameraNotifier();
    _cameraNotifier.addListener(_onCameraStateChanged);
    _initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Handle app lifecycle to prevent camera crashes
    if (_cameraNotifier.isDisposed) return;

    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // Pause camera when app goes to background
        _cameraNotifier.pauseCamera();
        break;
      case AppLifecycleState.resumed:
        // Resume camera when app comes back to foreground
        if (mounted && _cameraNotifier.state.isInitialized) {
          _cameraNotifier.resumeCamera();
        }
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _onCameraStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _initializeCamera() async {
    if (!mounted) return;
    try {
      await _cameraNotifier.initializeCamera();
    } catch (e) {
      // Error already handled in CameraNotifier
      debugPrint('Camera initialization error: $e');
    }
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
    if (!mounted) return;

    _cameraNotifier.pauseCamera(); // Pause camera before navigating
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreviewScreen(imagePath: imagePath),
      ),
    ).then((_) {
      // Resume camera when coming back (only if still mounted)
      if (mounted && !_cameraNotifier.isDisposed) {
        _cameraNotifier.resumeCamera();
      }
    });
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
    WidgetsBinding.instance.removeObserver(this);
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
            const Center(child: CircularProgressIndicator(color: Colors.white))
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
            // Fix for Aspect Ratio to prevent "Gepeng" on tall screens like POCO X7 Pro
            LayoutBuilder(
              builder: (context, constraints) {
                final scale =
                    1 /
                    (cameraController.value.aspectRatio *
                        constraints.maxHeight /
                        constraints.maxWidth);
                return Transform.scale(
                  scale: scale < 1 ? 1 / scale : scale,
                  child: Center(
                    child: CameraPreviewWidget(
                      cameraController: cameraController,
                    ),
                  ),
                );
              },
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // Gamification Overlay (Guide Box & Text)
          if (state.isInitialized && cameraController != null)
            _buildCameraOverlay(context),

          // Top Controls
          if (state.isInitialized && cameraController != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: CameraTopControlsWidget(
                  isFlashOn: state.isFlashOn,
                  onFlashToggle: _cameraNotifier.toggleFlash,
                  onClose: () => Navigator.pop(context),
                ),
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

  Widget _buildCameraOverlay(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Darkened Background with Cutout
        CustomPaint(painter: ScannerOverlayPainter()),
        // Guide Text and Corners
        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 100), // Space from top controls
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Posisikan struk dalam bingkai",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              // Space for the scanning area is handled by the Painter
              const Spacer(),
              const SizedBox(height: 180), // Space for bottom controls
            ],
          ),
        ),
      ],
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.5);

    // Define the scanning area
    final scanWidth = size.width * 0.85;
    final scanHeight = size.height * 0.6;
    final scanRect = Rect.fromCenter(
      center: Offset(
        size.width / 2,
        size.height / 2 - 40,
      ), // Slight offset upwards
      width: scanWidth,
      height: scanHeight,
    );

    // Draw the darkened background with a hole
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(
          RRect.fromRectAndRadius(scanRect, const Radius.circular(16)),
        ),
      ),
      paint,
    );

    // Draw the corner borders
    final borderPaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final cornerLength = 40.0;

    // Top Left
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.left, scanRect.top + cornerLength)
        ..lineTo(scanRect.left, scanRect.top)
        ..lineTo(scanRect.left + cornerLength, scanRect.top),
      borderPaint,
    );

    // Top Right
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.right - cornerLength, scanRect.top)
        ..lineTo(scanRect.right, scanRect.top)
        ..lineTo(scanRect.right, scanRect.top + cornerLength),
      borderPaint,
    );

    // Bottom Right
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.right, scanRect.bottom - cornerLength)
        ..lineTo(scanRect.right, scanRect.bottom)
        ..lineTo(scanRect.right - cornerLength, scanRect.bottom),
      borderPaint,
    );

    // Bottom Left
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.left + cornerLength, scanRect.bottom)
        ..lineTo(scanRect.left, scanRect.bottom)
        ..lineTo(scanRect.left, scanRect.bottom - cornerLength),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
