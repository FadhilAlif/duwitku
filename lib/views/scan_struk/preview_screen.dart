import 'dart:io';
import 'package:duwitku/models/receipt_item.dart';
import 'package:duwitku/services/receipt_service.dart';
import 'package:duwitku/views/scan_struk/receipt_review_screen.dart';
import 'package:flutter/material.dart';

class PreviewScreen extends StatefulWidget {
  final String imagePath;

  const PreviewScreen({super.key, required this.imagePath});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  bool _isLoading = false;
  String _loadingStatus = '';
  final _receiptService = ReceiptService();

  Future<void> _processReceipt() async {
    setState(() {
      _isLoading = true;
      _loadingStatus = 'Mengunggah gambar...';
    });

    try {
      final file = File(widget.imagePath);

      // Execute upload and analysis in parallel for efficiency
      final results = await Future.wait([
        _receiptService.uploadReceiptImage(file),
        _receiptService.analyzeReceipt(file),
      ]);

      final imageUrl = results[0] as String;
      final items = results[1] as List<ReceiptItem>;

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      // 3. Navigate to Review
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ReceiptReviewScreen(items: items, imageUrl: imageUrl),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memproses struk: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Pratinjau'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _processReceipt,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.file(
                      File(widget.imagePath),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.pop(context),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Ambil Ulang'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _processReceipt,
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Gunakan Foto'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      _loadingStatus,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
