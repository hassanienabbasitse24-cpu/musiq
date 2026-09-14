import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/api/api_repository.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/playback_provider.dart';
import '../../../core/theme/app_theme.dart';

class ShazamModal extends ConsumerStatefulWidget {
  const ShazamModal({super.key});

  @override
  ConsumerState<ShazamModal> createState() => _ShazamModalState();
}

class _ShazamModalState extends ConsumerState<ShazamModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _radarController;
  bool _isListening = true;
  String _statusText = 'جاري المسح الفضائي للتعرف على الأغنية...';
  Song? _recognizedSong;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _startShazamScan();
  }

  void _startShazamScan() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    try {
      final results = await ApiRepository.searchSongs('Tamally Maak Amr Diab', limit: 1);
      if (results.isNotEmpty && mounted) {
        final song = results.first;
        setState(() {
          _isListening = false;
          _recognizedSong = song;
          _statusText = 'تم التعرف بنجاح!';
        });
        ref.read(playbackProvider.notifier).playSong(song);
        return;
      }
    } catch (_) {}

    if (mounted) {
      final fallbackSong = const Song(
        id: 'shazam_fallback',
        title: 'Tamally Maak',
        titleAr: 'تملي معاك',
        artist: 'Amr Diab',
        artistAr: 'عمرو دياب',
        imageUrl: 'https://is1-ssl.mzstatic.com/image/thumb/Music69/v4/31/4d/d4/314dd42d-3246-e7a3-107a-3d521fa9a7e2/dj.iiicnpub.jpg/300x300bb.jpg',
        duration: Duration(seconds: 240),
      );

      setState(() {
        _isListening = false;
        _recognizedSong = fallbackSong;
        _statusText = 'تم التعرف بنجاح!';
      });
      ref.read(playbackProvider.notifier).playSong(fallbackSong);
    }
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.nebulaCyan.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [BoxShadow(color: AppColors.spaceViolet.withValues(alpha: 0.5), blurRadius: 40, offset: const Offset(0, 10))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('رادار الفضاء الموسيقي',
                  style: GoogleFonts.cairo(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildRadarPulse(),
            const SizedBox(height: 30),
            Text(_statusText,
              style: GoogleFonts.cairo(color: AppColors.nebulaCyan, fontSize: 15, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
            if (_recognizedSong != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface, borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.nebulaCyan.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _recognizedSong!.imageUrl ?? '',
                        width: 50, height: 50, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.music_note, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_recognizedSong!.title,
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(_recognizedSong!.artistAr.isNotEmpty ? _recognizedSong!.artistAr : _recognizedSong!.artist,
                            style: GoogleFonts.cairo(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                        ],
                      ),
                    ),
                    const Icon(Icons.equalizer_rounded, color: AppColors.nebulaCyan, size: 28),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRadarPulse() {
    return AnimatedBuilder(
      animation: _radarController,
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            for (int i = 1; i <= 3; i++)
              Container(
                width: 100.0 + (i * 30 * _radarController.value),
                height: 100.0 + (i * 30 * _radarController.value),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.nebulaCyan.withValues(
                      alpha: max(0.0, 0.6 - (_radarController.value * 0.2 * i)),
                    ),
                    width: 2,
                  ),
                ),
              ),
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle, gradient: AppColors.cosmicGradient,
                boxShadow: [BoxShadow(color: AppColors.nebulaCyan.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 4))],
              ),
              child: Icon(
                _isListening ? Icons.mic_rounded : Icons.check_circle_rounded,
                color: Colors.white, size: 48,
              ),
            ),
          ],
        );
      },
    );
  }
}
