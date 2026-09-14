import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/api/api_repository.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/library_provider.dart';
import '../../../core/providers/playback_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/space_background.dart';
import '../../../core/widgets/space_nav_bar.dart';
import '../../equalizer/presentation/equalizer_modal.dart';
import '../../library/presentation/library_screen.dart';
import '../../playlist_detail/presentation/playlist_detail_screen.dart';
import '../../shazam/presentation/shazam_modal.dart';
import 'widgets/section_header.dart';
import 'widgets/mini_player.dart';
import '../../now_playing/presentation/now_playing_screen.dart';
import '../../ai_assistant/presentation/ai_assistant_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentNavIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  List<Song> _searchResults = [];
  bool _isSearching = false;
  bool _showSearchResults = false;

  List<Song> _trendingSongs = [];
  List<Song> _popSongs = [];
  List<Song> _chillSongs = [];
  List<Song> _electronicSongs = [];
  bool _isLoadingHome = true;

  @override
  void initState() {
    super.initState();
    _loadHomeContent();
  }

  Future<void> _loadHomeContent() async {
    final trending = await ApiRepository.browseSongs(limit: 10, order: 'popularity_total');
    final pop = await ApiRepository.searchSongs('pop hits', limit: 10);
    final chill = await ApiRepository.searchSongs('chill relaxing', limit: 10);
    final electronic = await ApiRepository.searchSongs('electronic dance', limit: 10);

    if (mounted) {
      setState(() {
        _trendingSongs = trending;
        _popSongs = pop;
        _chillSongs = chill;
        _electronicSongs = electronic;
        _isLoadingHome = false;
      });
    }
  }

  void _onSearchChanged(String query) async {
    final text = query.trim();
    if (text.isEmpty) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showSearchResults = true;
    });

    try {
      final results = await ApiRepository.searchSongs(text);
      if (mounted && _searchController.text.trim() == text) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _openShazam() {
    showDialog(context: context, builder: (_) => const ShazamModal());
  }

  void _openEqualizer() {
    showDialog(context: context, builder: (_) => const EqualizerModal());
  }

  void _openPlaylistDetail(String title, String titleAr, String subtitle, Color color, String searchQuery) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlaylistDetailScreen(
          title: title,
          titleAr: titleAr,
          subtitle: subtitle,
          themeColor: color,
          searchQuery: searchQuery,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PlaybackState>(playbackProvider, (prev, next) {
      if (next.currentSong != null &&
          (prev == null || prev.currentSong?.id != next.currentSong!.id)) {
        ref.read(libraryProvider.notifier).addToHistory(next.currentSong!);
      }
    });

    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SpaceBackground(
        child: Stack(
          children: [
            Positioned.fill(child: _buildTabContent(topPadding)),
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMiniPlayerSection(context),
                  SpaceNavBar(
                    currentIndex: _currentNavIndex,
                    onTapTab: (index) => setState(() => _currentNavIndex = index),
                    onTapShazam: _openShazam,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(double topPadding) {
    switch (_currentNavIndex) {
      case 0: return _buildHomeContent(topPadding);
      case 1: return const AiAssistantScreen(isEmbedded: true);
      case 2: return const LibraryScreen(isEmbedded: true);
      default: return _buildHomeContent(topPadding);
    }
  }

  Widget _buildHomeContent(double topPadding) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: topPadding),
          _buildGradientHeader(context),
          const SizedBox(height: 20),
          _buildBrandTitle(),
          const SizedBox(height: 20),
          _buildSearchBar(),
          const SizedBox(height: 24),
          if (_showSearchResults) _buildSearchResultsOverlay(),
          if (!_showSearchResults) ...[
            SectionHeader(titleEn: 'Trending Now', titleAr: 'الأكثر رواجاً'),
            const SizedBox(height: 14),
            _buildSongHorizontalList(_trendingSongs),
            const SizedBox(height: 32),
            SectionHeader(titleEn: 'Pop Hits', titleAr: 'هيتس بوب'),
            const SizedBox(height: 14),
            _buildSongHorizontalList(_popSongs),
            const SizedBox(height: 32),
            SectionHeader(titleEn: 'Chill Vibes', titleAr: 'أجواء استرخائية'),
            const SizedBox(height: 14),
            _buildSongHorizontalList(_chillSongs),
            const SizedBox(height: 32),
            SectionHeader(titleEn: 'Electronic', titleAr: 'إلكتروني'),
            const SizedBox(height: 14),
            _buildSongHorizontalList(_electronicSongs),
            const SizedBox(height: 170),
          ],
        ],
      ),
    );
  }

  Widget _buildSongHorizontalList(List<Song> songs) {
    if (_isLoadingHome) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator(color: AppColors.nebulaCyan)),
      );
    }
    if (songs.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'جاري التحميل...',
            style: GoogleFonts.cairo(color: Colors.white38, fontSize: 14),
          ),
        ),
      );
    }
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: songs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final song = songs[index];
          return GestureDetector(
            onTap: () {
              final idx = songs.indexWhere((s) => s.id == song.id);
              ref.read(playbackProvider.notifier).setQueue(songs, startIndex: idx >= 0 ? idx : 0);
            },
            child: SizedBox(
              width: 140,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.nebulaCyan.withValues(alpha: 0.3), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.spaceViolet.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: song.imageUrl != null
                          ? Image.network(song.imageUrl!, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildSongPlaceholder())
                          : _buildSongPlaceholder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    song.title,
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song.artist,
                    style: GoogleFonts.cairo(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSongPlaceholder() {
    return Container(
      color: AppColors.surface,
      child: const Icon(Icons.music_note_rounded, color: AppColors.nebulaCyan, size: 48),
    );
  }

  Widget _buildGradientHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          _buildCircularIcon(icon: Icons.auto_awesome_rounded, glowColor: AppColors.nebulaCyan,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AiAssistantScreen()))),
          const SizedBox(width: 10),
          _buildCircularIcon(icon: Icons.graphic_eq_rounded, glowColor: AppColors.spaceViolet, onTap: _openEqualizer),
          const Spacer(),
          _buildGreeting(),
          const Spacer(),
          _buildProfileAvatar(),
        ],
      ),
    );
  }

  Widget _buildCircularIcon({required IconData icon, Color glowColor = AppColors.starlightBlue, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle, color: AppColors.surface,
          border: Border.all(color: glowColor.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [BoxShadow(color: glowColor.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 2))],
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildGreeting() {
    return Column(
      children: [
        Text('أهلاً بك في الفضاء الموسيقي',
          style: GoogleFonts.cairo(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text('Musiq Universe',
          style: GoogleFonts.poppins(color: AppColors.nebulaCyan, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildProfileAvatar() {
    return Container(
      width: 46, height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.nebulaCyan, width: 2),
        boxShadow: [BoxShadow(color: AppColors.nebulaCyan.withValues(alpha: 0.4), blurRadius: 10)],
      ),
      child: ClipOval(child: Image.asset('assets/app_icon.png', fit: BoxFit.cover)),
    );
  }

  Widget _buildBrandTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset('assets/app_icon.png', width: 42, height: 42, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text('موزيك الفضائي',
              style: GoogleFonts.cairo(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(27),
          border: Border.all(color: AppColors.nebulaCyan.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [BoxShadow(color: AppColors.nebulaCyan.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            const SizedBox(width: 18),
            const Icon(Icons.search_rounded, color: AppColors.nebulaCyan, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: GoogleFonts.cairo(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                  hintText: 'ابحث عن أغنية أو فنان...',
                  hintStyle: GoogleFonts.cairo(color: Colors.white.withValues(alpha: 0.35), fontSize: 14),
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear_rounded, color: Colors.white54, size: 20),
                onPressed: () { _searchController.clear(); _onSearchChanged(''); },
              ),
            GestureDetector(
              onTap: _openShazam,
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                width: 40, height: 40,
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.cosmicGradient),
                child: const Icon(Icons.mic_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultsOverlay() {
    if (_isSearching) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: AppColors.nebulaCyan)),
      );
    }

    if (_searchResults.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text('لم نجد نتائج مطابقة',
            style: GoogleFonts.cairo(color: Colors.white.withValues(alpha: 0.5), fontSize: 16)),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _searchResults.length,
        separatorBuilder: (_, __) => Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
        itemBuilder: (context, index) {
          final song = _searchResults[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                final idx = _searchResults.indexWhere((s) => s.id == song.id);
                ref.read(playbackProvider.notifier).setQueue(_searchResults, startIndex: idx >= 0 ? idx : 0);
              },
            ),
            onTap: () {
              final idx = _searchResults.indexWhere((s) => s.id == song.id);
              ref.read(playbackProvider.notifier).setQueue(_searchResults, startIndex: idx >= 0 ? idx : 0);
            },
          );
        },
      ),
    );
  }

  Widget _buildMiniPlayerSection(BuildContext context) {
    return MiniPlayer(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (_, __, ___) => const NowPlayingScreen(),
            transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
          ),
        );
      },
    );
  }
}
