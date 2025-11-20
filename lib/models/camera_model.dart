import 'package:camera/camera.dart';

class CameraModel {
  final String? imagePath;
  final bool isFlashOn;
  final CameraLensDirection lensDirection;
  final bool isInitialized;
  final bool hasPermission;
  final bool isPermanentlyDenied;
  final String? errorMessage;
  final bool isLoading;

  const CameraModel({
    this.imagePath,
    this.isFlashOn = false,
    this.lensDirection = CameraLensDirection.back,
    this.isInitialized = false,
    this.hasPermission = false,
    this.isPermanentlyDenied = false,
    this.errorMessage,
    this.isLoading = false,
  });

  CameraModel copyWith({
    String? imagePath,
    bool? isFlashOn,
    CameraLensDirection? lensDirection,
    bool? isInitialized,
    bool? hasPermission,
    bool? isPermanentlyDenied,
    String? errorMessage,
    bool? isLoading,
  }) {
    return CameraModel(
      imagePath: imagePath ?? this.imagePath,
      isFlashOn: isFlashOn ?? this.isFlashOn,
      lensDirection: lensDirection ?? this.lensDirection,
      isInitialized: isInitialized ?? this.isInitialized,
      hasPermission: hasPermission ?? this.hasPermission,
      isPermanentlyDenied: isPermanentlyDenied ?? this.isPermanentlyDenied,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  String toString() {
    return 'CameraModel{imagePath: $imagePath, isFlashOn: $isFlashOn, lensDirection: $lensDirection, isInitialized: $isInitialized, hasPermission: $hasPermission, isPermanentlyDenied: $isPermanentlyDenied, errorMessage: $errorMessage, isLoading: $isLoading}';
  }
}
