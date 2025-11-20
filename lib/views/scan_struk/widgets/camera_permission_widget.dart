import 'package:flutter/material.dart';

class CameraPermissionWidget extends StatelessWidget {
  final bool isPermanentlyDenied;
  final VoidCallback onRequestPermission;

  const CameraPermissionWidget({
    super.key,
    required this.isPermanentlyDenied,
    required this.onRequestPermission,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              isPermanentlyDenied
                  ? 'Izin Kamera Ditolak'
                  : 'Izin Kamera Diperlukan',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              isPermanentlyDenied
                  ? 'Silakan buka pengaturan aplikasi untuk mengaktifkan izin kamera.'
                  : 'Aplikasi memerlukan akses ke kamera untuk mengambil foto struk.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onRequestPermission,
              icon: Icon(isPermanentlyDenied ? Icons.settings : Icons.camera_alt),
              label: Text(
                isPermanentlyDenied ? 'Buka Pengaturan' : 'Berikan Izin',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
