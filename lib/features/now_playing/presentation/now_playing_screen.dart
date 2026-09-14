import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/providers/playback_provider.dart';
import '../../../core/providers/library_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/space_background.dart';
import 'widgets/lyrics_bottom_sheet.dart';

class NowPlayingScreen extends ConsumerStatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen>
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
    final size = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;

    ref.listen<PlaybackState>(playbackProvider, (prev, next) {
      if (next.isPlaying && !_waveController.isAnimating) {
        _waveController.repeat();
      } else if (!next.isPlaying && _waveController.isAnimating) {
        _waveController.stop();
      }
    });

    return Scaffold(
      body: SpaceBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(playback, topPadding),
              const SizedBox(height: 16),
              _buildAlbumArt(size, playback),
              const SizedBox(height: 36),
              _buildSongInfo(playback),
              const SizedBox(height: 28),
              _buildProgressSlider(playback),
              const SizedBox(height: 20),
              _buildMainControls(playback),
              const SizedBox(height: 24),
              _buildSecondaryControls(playback),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(PlaybackState playback, double topPadding) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCircleButton(
            icon: Icons.keyboard_arrow_down_rounded,
            size: 44,
            onTap: () => Navigator.pop(context),
          ),
          Column(
            children: [
              Text(
                'COSMIC STATION',
                style: GoogleFonts.poppins(
                  color: AppColors.nebulaCyan,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Musiq Galaxy Queue',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          _buildCircleButton(
            icon: playback.isFavorite
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            size: 44,
            iconColor: playback.isFavorite ? AppColors.supernovaPink : Colors.white,
            onTap: () {
              ref.read(playbackProvider.notifier).toggleFavorite();
              final song = playback.currentSong;
              if (song != null) {
                ref.read(libraryProvider.notifier).toggleFavorite(song);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required double size,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: iconColor ?? Colors.white,
          size: size * 0.5,
        ),
      ),
    );
  }

  Widget _buildAlbumArt(Size size, PlaybackState playback) {
    final artSize = size.width * 0.68;
    final song = playback.currentSong;

    return Hero(
      tag: 'album_art',
      child: Container(
        width: artSize,
        height: artSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: AppColors.nebulaCyan.withValues(alpha: 0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.spaceViolet.withValues(alpha: 0.4),
              blurRadius: 50,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: AppColors.nebulaCyan.withValues(alpha: 0.3),
              blurRadius: 60,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Text(
            song?.title ?? 'Cosmic Track',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            song?.artistAr ?? song?.artist ?? 'Galaxy Artist',
            style: GoogleFonts.cairo(
              color: AppColors.nebulaCyan,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSlider(PlaybackState playback) {
    final current = playback.currentPosition;
    final total = playback.totalDuration;
    final progress = total.inSeconds > 0 ? current.inSeconds / total.inSeconds : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
              activeTrackColor: AppColors.nebulaCyan,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
              thumbColor: Colors.white,
              overlayColor: AppColors.nebulaCyan.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              onChanged: (value) {
                final position = Duration(
                  seconds: (value * total.inSeconds).round(),
                );
                ref.read(playbackProvider.notifier).seekTo(position);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(current),
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
                Text(
                  _formatDuration(total),
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildMainControls(PlaybackState playback) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildControlCircle(
          icon: Icons.shuffle_rounded,
          isActive: playback.isShuffle,
          size: 50,
          onTap: () => ref.read(playbackProvider.notifier).toggleShuffle(),
        ),
        const SizedBox(width: 24),
        _buildControlCircle(
          icon: Icons.skip_previous_rounded,
          size: 58,
          onTap: () => ref.read(playbackProvider.notifier).skipToPrevious(),
        ),
        const SizedBox(width: 20),
        _buildPlayPauseButton(playback.isPlaying),
        const SizedBox(width: 20),
        _buildControlCircle(
          icon: Icons.skip_next_rounded,
          size: 58,
          onTap: () => ref.read(playbackProvider.notifier).skipToNext(),
        ),
        const SizedBox(width: 24),
        _buildControlCircle(
          icon: _getRepeatIcon(playback.repeatMode),
          isActive: playback.repeatMode != SongRepeatMode.off,
          size: 50,
          onTap: () => ref.read(playbackProvider.notifier).cycleRepeat(),
        ),
      ],
    );
  }

  Widget _buildPlayPauseButton(bool isPlaying) {
    return GestureDetector(
      onTap: () => ref.read(playbackProvider.notifier).togglePlayPause(),
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.cosmicGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.nebulaCyan.withValues(alpha: 0.45),
              blurRadius: 28,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            key: ValueKey(isPlaying),
            color: Colors.white,
            size: 40,
          ),
        ),
      ),
    );
  }

  Widget _buildControlCircle({
    required IconData icon,
    required double size,
    bool isActive = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive
              ? AppColors.nebulaCyan.withValues(alpha: 0.2)
              : AppColors.surface,
          border: Border.all(
            color: isActive ? AppColors.nebulaCyan : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Icon(
          icon,
          color: isActive ? AppColors.nebulaCyan : Colors.white,
          size: size * 0.44,
        ),
      ),
    );
  }

  IconData _getRepeatIcon(SongRepeatMode mode) {
    switch (mode) {
      case SongRepeatMode.off:
        return Icons.repeat_rounded;
      case SongRepeatMode.all:
        return Icons.repeat_rounded;
      case SongRepeatMode.one:
        return Icons.repeat_one_rounded;
    }
  }

  Widget _buildSecondaryControls(PlaybackState playback) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCircleButton(
            icon: Icons.lyrics_outlined,
            size: 42,
            onTap: () => _showLyricsSheet(context),
          ),
          _buildDownloadButton(playback),
          _buildWaveIndicator(playback.isPlaying),
          _buildCircleButton(
            icon: Icons.queue_music_rounded,
            size: 42,
            onTap: () => _showQueueSheet(context),
          ),
          _buildCircleButton(
            icon: Icons.share_rounded,
            size: 42,
            onTap: () {
              final s = playback.currentSong;
              if (s != null) {
                final text = '${s.titleAr.isNotEmpty ? s.titleAr : s.title} — ${s.artistAr.isNotEmpty ? s.artistAr : s.artist}';
                Share.share('🎵 $text\nListen on Musiq!');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadButton(PlaybackState playback) {
    final isDownloading = playback.isDownloading;
    final isDownloaded = playback.isDownloaded;
    final progress = playback.downloadProgress;

    return GestureDetector(
      onTap: () async {
        if (isDownloaded) {
          await ref.read(playbackProvider.notifier).deleteCurrentDownload();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'تم إزالة الأغنية من المحمّلات',
                  style: GoogleFonts.cairo(),
                ),
                backgroundColor: AppColors.surface,
              ),
            );
          }
        } else if (!isDownloading) {
          await ref.read(playbackProvider.notifier).downloadCurrentSong();
          if (mounted) {
            final isNowDownloaded = ref.read(playbackProvider).isDownloaded;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isNowDownloaded
                      ? 'تم تحميل الأغنية للاستماع بدون إنترنت'
                      : 'لا يمكن تحميل هذه الأغنية',
                  style: GoogleFonts.cairo(),
                ),
                backgroundColor: isNowDownloaded ? AppColors.nebulaCyan : AppColors.surface,
              ),
            );
          }
        }
      },
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDownloaded
              ? AppColors.nebulaCyan.withValues(alpha: 0.2)
              : AppColors.surface,
          border: Border.all(
            color: isDownloaded
                ? AppColors.nebulaCyan
                : Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: isDownloading
            ? Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 2.5,
                    color: AppColors.nebulaCyan,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                  ),
                  Text(
                    '${(progress * 100).round()}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : Icon(
                isDownloaded ? Icons.download_done_rounded : Icons.download_for_offline_rounded,
                color: isDownloaded ? AppColors.nebulaCyan : Colors.white,
                size: 22,
              ),
      ),
    );
  }

  Widget _buildWaveIndicator(bool isPlaying) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(7, (index) {
            final height = _getWaveHeight(index, isPlaying);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 3.5,
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
    final sine = sin((_waveController.value * 2 * pi) + (index * 0.9));
    return 5 + (sine * 0.5 + 0.5) * 20;
  }

  void _showLyricsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LyricsBottomSheet(),
    );
  }

  void _showQueueSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QueueSheet(),
    );
  }
}

class _QueueSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playback = ref.watch(playbackProvider);
    final queue = playback.queue;
    final currentId = playback.currentSong?.id;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF121228),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: AppColors.nebulaCyan.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Queue',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: queue.isEmpty
                    ? Center(
                        child: Text(
                          'Queue is empty',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: queue.length,
                        itemBuilder: (context, index) {
                          final song = queue[index];
                          final isCurrent = song.id == currentId;
                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: song.imageUrl != null
                                  ? Image.network(
                                      song.imageUrl!,
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 44,
                                        height: 44,
                                        color: AppColors.surface,
                                        child: const Icon(Icons.music_note, color: Colors.white),
                                      ),
                                    )
                                  : Container(
                                      width: 44,
                                      height: 44,
                                      color: AppColors.surface,
                                      child: const Icon(Icons.music_note, color: Colors.white),
                                    ),
                            ),
                            title: Text(
                              song.titleAr.isNotEmpty ? song.titleAr : song.title,
                              style: GoogleFonts.poppins(
                                color: isCurrent ? AppColors.nebulaCyan : Colors.white,
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              song.artistAr.isNotEmpty ? song.artistAr : song.artist,
                              style: GoogleFonts.cairo(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 12,
                              ),
                            ),
                            trailing: isCurrent
                                ? Icon(Icons.equalizer, color: AppColors.nebulaCyan)
                                : IconButton(
                                    icon: Icon(
                                      Icons.close,
                                      color: Colors.white.withValues(alpha: 0.3),
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      ref.read(playbackProvider.notifier).removeFromQueue(index);
                                    },
                                  ),
                            onTap: () {
                              ref.read(playbackProvider.notifier).setQueue(queue, startIndex: index);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
