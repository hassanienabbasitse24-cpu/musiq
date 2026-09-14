import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/library_provider.dart';
import '../../../core/providers/playback_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/space_background.dart';
import '../../home/presentation/widgets/mini_player.dart';
import '../../now_playing/presentation/now_playing_screen.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  final bool isEmbedded;

  const LibraryScreen({super.key, this.isEmbedded = false});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(libraryProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    if (widget.isEmbedded) {
      return _buildContent(library, topPadding);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SpaceBackground(
        child: Stack(
          children: [
            _buildContent(library, topPadding),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MiniPlayer(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NowPlayingScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(LibraryState library, double topPadding) {
    return Column(
      children: [
        SizedBox(height: topPadding + 10),
        _buildHeader(),
        _buildTabBar(),
        const SizedBox(height: 12),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSongList(library.favoriteSongs, 'لا توجد أغاني مفضلة بعد'),
              _buildSongList(library.downloadedSongs, 'لا توجد أغاني محملة بدون إنترنت'),
              _buildSongList(library.recentHistory, 'سجل الاستماع فارغ حالياً'),
            ],
          ),
        ),
        const SizedBox(height: 120),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'مكتبتي الفضائية',
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.nebulaCyan.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.bookmark_border_rounded, color: AppColors.nebulaCyan, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: AppColors.cosmicGradient,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
        labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12),
        tabs: const [
          Tab(text: '❤️ المفضلة'),
          Tab(text: '⚡ بدون إنترنت'),
          Tab(text: '🕒 سجل الاستماع'),
        ],
      ),
    );
  }

  Widget _buildSongList(List<Song> songs, String emptyMessage) {
    if (songs.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: GoogleFonts.cairo(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        final isDownloaded = ref.read(libraryProvider.notifier).isDownloaded(song.id);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.nebulaCyan.withValues(alpha: 0.15)),
          ),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: song.imageUrl != null
                  ? Image.network(song.imageUrl!, width: 48, height: 48, fit: BoxFit.cover)
                  : Container(width: 48, height: 48, color: AppColors.spaceViolet, child: const Icon(Icons.music_note, color: Colors.white)),
            ),
            title: Text(
              song.title,
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Row(
              children: [
                if (isDownloaded) ...[
                  const Icon(Icons.offline_pin_rounded, color: AppColors.nebulaCyan, size: 14),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    song.artistAr.isNotEmpty ? song.artistAr : song.artist,
                    style: GoogleFonts.cairo(color: Colors.white.withValues(alpha: 0.65), fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    isDownloaded ? Icons.download_done_rounded : Icons.download_for_offline_rounded,
                    color: isDownloaded ? AppColors.nebulaCyan : Colors.white38,
                    size: 24,
                  ),
                  onPressed: () async {
                    final isNowDownloaded = await ref.read(libraryProvider.notifier).toggleDownload(song);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isNowDownloaded
                                ? 'تم تحميل الأغنية للاستماع بدون إنترنت ⚡'
                                : 'تم إزالة الأغنية من المحمّلات',
                            style: GoogleFonts.cairo(),
                          ),
                          backgroundColor: AppColors.surface,
                        ),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.play_arrow_rounded, color: AppColors.nebulaCyan, size: 30),
                  onPressed: () {
                    ref.read(playbackProvider.notifier).playSong(song);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
