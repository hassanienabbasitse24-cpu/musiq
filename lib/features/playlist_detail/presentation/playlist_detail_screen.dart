import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/api/api_repository.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/playback_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/space_background.dart';
import '../../home/presentation/widgets/mini_player.dart';
import '../../now_playing/presentation/now_playing_screen.dart';

class PlaylistDetailScreen extends ConsumerStatefulWidget {
  final String title;
  final String titleAr;
  final String subtitle;
  final Color themeColor;
  final String searchQuery;

  const PlaylistDetailScreen({
    super.key,
    required this.title,
    required this.titleAr,
    required this.subtitle,
    required this.themeColor,
    required this.searchQuery,
  });

  @override
  ConsumerState<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends ConsumerState<PlaylistDetailScreen> {
  List<Song> _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylistSongs();
  }

  void _loadPlaylistSongs() async {
    final results = await ApiRepository.searchSongs(widget.searchQuery);
    if (mounted) {
      setState(() {
        _songs = results;
        _isLoading = false;
      });
    }
  }

  void _playAll() {
    if (_songs.isNotEmpty) {
      ref.read(playbackProvider.notifier).setQueue(_songs, startIndex: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SpaceBackground(
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(height: topPadding),
                  _buildHeader(context),
                  _buildBanner(),
                  const SizedBox(height: 20),
                  _buildPlayAllBar(),
                  const SizedBox(height: 16),
                  _buildSongList(),
                  const SizedBox(height: 120),
                ],
              ),
            ),
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: MiniPlayer(onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NowPlayingScreen()));
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.surface,
                border: Border.all(color: Colors.white.withValues(alpha: 0.15))),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(widget.titleAr,
              style: GoogleFonts.cairo(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: widget.themeColor.withValues(alpha: 0.5), width: 1.5),
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [
            widget.themeColor.withValues(alpha: 0.7),
            AppColors.spaceViolet.withValues(alpha: 0.4),
          ],
        ),
        boxShadow: [BoxShadow(color: widget.themeColor.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
                    color: Colors.white.withValues(alpha: 0.1)),
                  child: const Icon(Icons.library_music_rounded, color: Colors.white, size: 48),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title,
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(widget.subtitle,
                        style: GoogleFonts.cairo(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
                      const SizedBox(height: 8),
                      Text('${_songs.length} أغنية',
                        style: GoogleFonts.cairo(color: AppColors.nebulaCyan, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayAllBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('قائمة الأغاني',
            style: GoogleFonts.cairo(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.nebulaCyan, foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: _playAll,
            icon: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 22),
            label: Text('تشغيل الكل', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildSongList() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: CircularProgressIndicator(color: AppColors.nebulaCyan),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _songs.length,
      itemBuilder: (context, index) {
        final song = _songs[index];
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: song.imageUrl != null
                  ? Image.network(song.imageUrl!, width: 46, height: 46, fit: BoxFit.cover)
                  : Container(width: 46, height: 46, color: AppColors.spaceViolet,
                      child: const Icon(Icons.music_note, color: Colors.white)),
            ),
            title: Text(song.title,
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(song.artist,
              style: GoogleFonts.cairo(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
            trailing: IconButton(
              icon: const Icon(Icons.play_circle_fill_rounded, color: AppColors.nebulaCyan, size: 36),
              onPressed: () {
                final idx = _songs.indexWhere((s) => s.id == song.id);
                ref.read(playbackProvider.notifier).setQueue(_songs, startIndex: idx >= 0 ? idx : 0);
              },
            ),
          ),
        );
      },
    );
  }
}
