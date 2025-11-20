import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/camera_model.dart';

class CameraNotifier extends ChangeNotifier {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  final ImagePicker _imagePicker = ImagePicker();
  CameraModel _state = const CameraModel();

  CameraNotifier();

  CameraModel get state => _state;
  CameraController? get cameraController => _cameraController;

  void _updateState(CameraModel newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> initializeCamera() async {
    _updateState(_state.copyWith(isLoading: true));

    try {
      // Check camera permission
      final status = await Permission.camera.status;

      if (status.isDenied) {
        final result = await Permission.camera.request();
        if (result.isDenied) {
          _updateState(_state.copyWith(
            hasPermission: false,
            isLoading: false,
            errorMessage: 'Izin kamera diperlukan untuk mengambil foto',
          ));
          return;
        }
        if (result.isPermanentlyDenied) {
          _updateState(_state.copyWith(
            hasPermission: false,
            isPermanentlyDenied: true,
            isLoading: false,
            errorMessage: 'Izin kamera ditolak secara permanen',
          ));
          return;
        }
      }

      if (status.isPermanentlyDenied) {
        _updateState(_state.copyWith(
          hasPermission: false,
          isPermanentlyDenied: true,
          isLoading: false,
          errorMessage: 'Izin kamera ditolak secara permanen',
        ));
        return;
      }

      // Get available cameras
      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        _updateState(_state.copyWith(
          isLoading: false,
          errorMessage: 'Tidak ada kamera yang tersedia',
        ));
        return;
      }

      // Find the back camera
      final camera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == _state.lensDirection,
        orElse: () => _cameras!.first,
      );

      // Initialize camera controller
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      _updateState(_state.copyWith(
        isInitialized: true,
        hasPermission: true,
        isLoading: false,
        errorMessage: null,
      ));
    } catch (e) {
      _updateState(_state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal menginisialisasi kamera: ${e.toString()}',
      ));
    }
  }

  Future<void> toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final newFlashMode = _state.isFlashOn ? FlashMode.off : FlashMode.torch;
      await _cameraController!.setFlashMode(newFlashMode);
      _updateState(_state.copyWith(isFlashOn: !_state.isFlashOn));
    } catch (e) {
      _updateState(_state.copyWith(
        errorMessage: 'Gagal mengubah flash: ${e.toString()}',
      ));
    }
  }

  Future<void> switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) {
      return;
    }

    _updateState(_state.copyWith(isLoading: true));

    try {
      // Dispose current controller
      await _cameraController?.dispose();

      // Switch lens direction
      final newLensDirection = _state.lensDirection == CameraLensDirection.back
          ? CameraLensDirection.front
          : CameraLensDirection.back;

      // Find camera with new lens direction
      final camera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == newLensDirection,
        orElse: () => _cameras!.first,
      );

      // Initialize new controller
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      _updateState(_state.copyWith(
        lensDirection: newLensDirection,
        isInitialized: true,
        isLoading: false,
        isFlashOn: false,
      ));
    } catch (e) {
      _updateState(_state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal mengganti kamera: ${e.toString()}',
      ));
    }
  }

  Future<String?> takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return null;
    }

    try {
      final XFile image = await _cameraController!.takePicture();
      _updateState(_state.copyWith(imagePath: image.path));
      return image.path;
    } catch (e) {
      _updateState(_state.copyWith(
        errorMessage: 'Gagal mengambil foto: ${e.toString()}',
      ));
      return null;
    }
  }

  Future<String?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        _updateState(_state.copyWith(imagePath: image.path));
        return image.path;
      }
      return null;
    } catch (e) {
      _updateState(_state.copyWith(
        errorMessage: 'Gagal memilih gambar: ${e.toString()}',
      ));
      return null;
    }
  }

  void clearImage() {
    _updateState(_state.copyWith(imagePath: null));
  }

  void clearError() {
    _updateState(_state.copyWith(errorMessage: null));
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }
}
