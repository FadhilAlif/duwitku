import 'package:go_router/go_router.dart';
import 'package:duwitku/providers/category_provider.dart';
import 'package:duwitku/providers/gemini_provider.dart';
import 'package:duwitku/providers/wallet_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceInputScreen extends ConsumerStatefulWidget {
  const VoiceInputScreen({super.key});

  @override
  ConsumerState<VoiceInputScreen> createState() => _VoiceInputScreenState();
}

class _VoiceInputScreenState extends ConsumerState<VoiceInputScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = 'Tekan tombol mikrofon dan mulai bicara...';
  bool _isProcessing = false;
  bool _hasSpeech = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  @override
  void dispose() {
    // Ensure speech recognition is stopped when leaving the screen
    if (_isListening) {
      _speech.stop();
    }
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'notListening' && _isListening) {
            setState(() => _isListening = false);
          }
        },
        onError: (error) {
          setState(() {
            _isListening = false;
            if (error.errorMsg != 'error_speech_timeout') {
              _text = 'Error: ${error.errorMsg}';
            }
          });
        },
      );
      if (mounted) {
        setState(() {
          _hasSpeech = available;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _text = 'Gagal inisialisasi suara: $e';
        });
      }
    }
  }

  void _toggleListening() async {
    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
    } else {
      if (!_hasSpeech) {
        await _initSpeech();
        if (!_hasSpeech) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Fitur suara tidak tersedia')),
            );
          }
          return;
        }
      }

      setState(() {
        _isListening = true;
        _text = ''; // Clear previous text
      });

      _speech.listen(
        onResult: (val) {
          setState(() {
            _text = val.recognizedWords;
          });
        },
        localeId: 'id_ID',
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: stt.ListenMode.confirmation,
        ),
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
      );
    }
  }

  Future<void> _processTransaction() async {
    if (_text.isEmpty || _text.startsWith('Tekan tombol')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon bicara terlebih dahulu')),
      );
      return;
    }

    setState(() => _isProcessing = true);
    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
    }

    try {
      final categories = await ref.read(categoriesStreamProvider.future);
      final wallets = await ref.read(walletsStreamProvider.future);

      final items = await ref
          .read(geminiServiceProvider)
          .analyzeTransactionFromText(
            text: _text,
            categories: categories,
            wallets: wallets,
          );

      if (mounted) {
        // Use push instead of pushReplacement to prevent provider disposal
        context.push('/voice_input_review', extra: items);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memproses: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Input Suara'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Sebutkan transaksi Anda',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Contoh: "Beli Nasi Goreng 25 ribu pakai Gopay"',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),

            // Text Output Area
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isListening
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _text.isEmpty && _isListening ? 'Mendengarkan...' : _text,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: (_text.isEmpty || _text.startsWith('Tekan tombol'))
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.onSurface,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Mic Button
            GestureDetector(
              onTap: _isProcessing ? null : _toggleListening,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                  boxShadow: [
                    BoxShadow(
                      color:
                          (_isListening
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.primary)
                              .withValues(alpha: 0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  _isListening ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Process Button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    (_text.isEmpty ||
                        _text.startsWith('Tekan tombol') ||
                        _isProcessing)
                    ? null
                    : _processTransaction,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle),
                label: Text(
                  _isProcessing ? 'Sedang Memproses...' : 'Proses Transaksi',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
