import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/providers/playback_provider.dart';
import '../../../../core/theme/app_theme.dart';

class MiniPlayer extends ConsumerStatefulWidget {
  final VoidCallback? onTap;

  const MiniPlayer({
    super.key,
    this.onTap,
  });

  @override
  ConsumerState<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends ConsumerState<MiniPlayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _waveController.repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playback = ref.watch(playbackProvider);

    if (playback.currentSong == null) {
      return const SizedBox.shrink();
    }

    ref.listen<PlaybackState>(playbackProvider, (prev, next) {
      if (next.isPlaying && !_waveController.isAnimating) {
        _waveController.repeat();
      } else if (!next.isPlaying && _waveController.isAnimating) {
        _waveController.stop();
      }
    });

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        height: 68,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.spaceViolet.withValues(alpha: 0.35),
              AppColors.headerStart.withValues(alpha: 0.45),
              AppColors.nebulaCyan.withValues(alpha: 0.25),
            ],
          ),
          border: Border.all(
            color: AppColors.nebulaCyan.withValues(alpha: 0.25),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.spaceViolet.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  _buildAlbumArt(playback),
                  const SizedBox(width: 12),
                  _buildSongInfo(playback),
                  const SizedBox(width: 6),
                  _buildWaveform(playback),
                  const SizedBox(width: 6),
                  _buildControls(playback),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumArt(PlaybackState playback) {
    final song = playback.currentSong;
    return Hero(
      tag: 'album_art',
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.cosmicGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.nebulaCyan.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: song?.imageUrl != null
              ? Image.network(
                  song!.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildFallbackArt(),
                )
              : _buildFallbackArt(),
        ),
      ),
    );
  }

  Widget _buildFallbackArt() {
    return Image.asset(
      'assets/app_icon.png',
      fit: BoxFit.cover,
    );
  }

  Widget _buildSongInfo(PlaybackState playback) {
    final song = playback.currentSong;
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            song?.title ?? 'Cosmic Track',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            song?.artistAr ?? song?.artist ?? 'Starlight Station',
            style: GoogleFonts.cairo(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildWaveform(PlaybackState playback) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(4, (index) {
            final height = _getWaveHeight(index, playback.isPlaying);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 3,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: AppColors.cosmicGradient,
              ),
            );
          }),
        );
      },
    );
  }

  double _getWaveHeight(int index, bool isPlaying) {
    if (!isPlaying) return 4;
    final sine = sin((_waveController.value * 2 * pi) + (index * 0.8));
    return 6 + (sine * 0.5 + 0.5) * 16;
  }

  Widget _buildControls(PlaybackState playback) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => ref.read(playbackProvider.notifier).togglePlayPause(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.cosmicGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.nebulaCyan.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              playback.isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            ref.read(playbackProvider.notifier).stop();
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }
}
