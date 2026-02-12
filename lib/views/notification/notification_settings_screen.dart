import 'package:duwitku/services/notification_service.dart';
import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _isEnabled = false;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 20, minute: 0);
  int _selectedTemplateIndex = 0;
  bool _isLoading = true;
  bool _isSaving = false;

  final _service = NotificationService.instance;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await _service.isEnabled();
    final time = await _service.getScheduledTime();
    final index = await _service.getSelectedTemplateIndex();
    if (mounted) {
      setState(() {
        _isEnabled = enabled;
        _selectedTime = time;
        _selectedTemplateIndex = index;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    try {
      await _service.setEnabled(_isEnabled);
      await _service.saveScheduledTime(_selectedTime);
      await _service.saveSelectedTemplateIndex(_selectedTemplateIndex);

      if (_isEnabled) {
        final granted = await _service.requestPermission();
        if (!granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Izin notifikasi ditolak. Aktifkan di pengaturan perangkat.',
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          setState(() {
            _isEnabled = false;
            _isSaving = false;
          });
          await _service.setEnabled(false);
          return;
        }

        final template = NotificationService.templates[_selectedTemplateIndex];
        await _service.scheduleDailyNotification(
          time: _selectedTime,
          template: template,
        );
      } else {
        await _service.cancelAll();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEnabled
                  ? 'Notifikasi dijadwalkan pukul ${_selectedTime.format(context)}'
                  : 'Notifikasi dinonaktifkan',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      helpText: 'Pilih Waktu Notifikasi',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pengaturan Notifikasi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Enable Toggle ──
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: _isEnabled
                                  ? const Color(0xFF14894e).withAlpha(25)
                                  : Colors.grey.withAlpha(25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _isEnabled
                                  ? Icons.notifications_active
                                  : Icons.notifications_off_outlined,
                              color: _isEnabled
                                  ? const Color(0xFF14894e)
                                  : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pengingat Harian',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  _isEnabled
                                      ? 'Notifikasi aktif'
                                      : 'Notifikasi nonaktif',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurface.withAlpha(150),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _isEnabled,
                            activeTrackColor: const Color(0xFF14894e),
                            onChanged: (val) {
                              setState(() => _isEnabled = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Time Picker ──
                  AnimatedOpacity(
                    opacity: _isEnabled ? 1.0 : 0.4,
                    duration: const Duration(milliseconds: 200),
                    child: IgnorePointer(
                      ignoring: !_isEnabled,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 20,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Waktu Notifikasi',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: InkWell(
                              onTap: _pickTime,
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _selectedTime.format(context),
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Tap untuk ubah waktu',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Notifikasi akan muncul setiap hari',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: colorScheme.onSurface
                                                  .withAlpha(150),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.edit,
                                      color: colorScheme.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ── Template Selector ──
                          Row(
                            children: [
                              Icon(
                                Icons.message_outlined,
                                size: 20,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Template Pesan',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...List.generate(
                            NotificationService.templates.length,
                            (index) {
                              final template =
                                  NotificationService.templates[index];
                              final isSelected =
                                  index == _selectedTemplateIndex;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _TemplateCard(
                                  template: template,
                                  isSelected: isSelected,
                                  onTap: () {
                                    setState(
                                      () => _selectedTemplateIndex = index,
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),

                          // ── Preview Card ──
                          Row(
                            children: [
                              Icon(
                                Icons.preview,
                                size: 20,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Preview Notifikasi',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _NotificationPreview(
                            template: NotificationService
                                .templates[_selectedTemplateIndex],
                            time: _selectedTime,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Save Button ──
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _saveSettings,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(_isSaving ? 'Menyimpan...' : 'Simpan'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF14894e),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final NotificationTemplate template;
  final bool isSelected;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.template,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: isSelected ? 2 : 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? const BorderSide(color: Color(0xFF14894e), width: 2)
            : BorderSide(color: colorScheme.outlineVariant.withAlpha(80)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF14894e).withAlpha(25)
                      : Colors.grey.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    template.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.title,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w600,
                        fontSize: 14,
                        color: isSelected
                            ? const Color(0xFF14894e)
                            : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      template.body,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withAlpha(160),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF14894e),
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationPreview extends StatelessWidget {
  final NotificationTemplate template;
  final TimeOfDay time;

  const _NotificationPreview({required this.template, required this.time});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              colorScheme.primaryContainer.withAlpha(80),
              colorScheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fake notification header
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF14894e),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Center(
                    child: Text(
                      'D',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Duwitku',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withAlpha(180),
                  ),
                ),
                const Spacer(),
                Text(
                  time.format(context),
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withAlpha(130),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              template.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              template.body,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withAlpha(200),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
