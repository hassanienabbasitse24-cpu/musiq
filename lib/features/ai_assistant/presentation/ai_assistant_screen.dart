import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/playback_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/space_background.dart';
import '../../home/presentation/widgets/mini_player.dart';
import '../../now_playing/presentation/now_playing_screen.dart';
import '../data/ai_repository.dart';
import 'widgets/wave_loading_indicator.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  final bool isEmbedded;

  const AiAssistantScreen({super.key, this.isEmbedded = false});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  MoodType? _selectedMood;
  bool _isLoading = false;
  List<Song> _results = [];
  bool _hasSearched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitQuery() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _selectedMood == null) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    final prompt = text.isNotEmpty ? text : _selectedMood!.searchQuery;

    try {
      final results = await AiRepository.getAiRecommendations(
        prompt,
        mood: _selectedMood,
      );
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e', style: GoogleFonts.cairo()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    if (widget.isEmbedded) {
      return Column(
        children: [
          SizedBox(height: topPadding),
          _buildHeader(),
          _buildMoodChips(),
          const SizedBox(height: 12),
          Expanded(child: _buildContentArea()),
          _buildChatInput(),
          const SizedBox(height: 130),
        ],
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SpaceBackground(
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(height: topPadding),
                _buildHeader(),
                _buildMoodChips(),
                const SizedBox(height: 12),
                Expanded(child: _buildContentArea()),
                const SizedBox(height: 130),
              ],
            ),
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildChatInput(),
                  MiniPlayer(onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NowPlayingScreen()));
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          if (!widget.isEmbedded) ...[
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
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ابحث بالذكاء الاصطناعي',
                  style: GoogleFonts.cairo(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                Text('AI Music Search',
                  style: GoogleFonts.poppins(color: AppColors.nebulaCyan, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(gradient: AppColors.cosmicGradient, borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 8, height: 8,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.success)),
                const SizedBox(width: 6),
                const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text('AI', style: GoogleFonts.orbitron(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodChips() {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: MoodType.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final mood = MoodType.values[index];
          final isSelected = _selectedMood == mood;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedMood = isSelected ? null : mood);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.cosmicGradient : null,
                color: isSelected ? null : AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected ? Colors.transparent : AppColors.nebulaCyan.withValues(alpha: 0.2), width: 1.2),
                boxShadow: isSelected
                    ? [BoxShadow(color: AppColors.nebulaCyan.withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 4))]
                    : null,
              ),
              child: Text(mood.labelAr,
                style: GoogleFonts.cairo(color: Colors.white, fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContentArea() {
    if (_isLoading) return _buildLoadingState();
    if (_results.isNotEmpty) return _buildResultsList();
    if (_hasSearched) return _buildEmptyState();
    return _buildIdleState();
  }

  Widget _buildIdleState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 86, height: 86,
              decoration: BoxDecoration(
                shape: BoxShape.circle, gradient: AppColors.cosmicGradient,
                boxShadow: [BoxShadow(color: AppColors.nebulaCyan.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 6))],
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 42),
            ),
            const SizedBox(height: 24),
            Text('اختر أجواء أو اكتب ما تشعر به',
              style: GoogleFonts.cairo(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('سيبحث الذكاء الاصطناعي عن أفضل الأغاني لك من Jamendo',
              style: GoogleFonts.cairo(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
              textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const WaveLoadingIndicator(barCount: 7, barWidth: 5, maxBarHeight: 44),
          const SizedBox(height: 24),
          Text('جاري البحث في Jamendo...',
            style: GoogleFonts.cairo(color: AppColors.nebulaCyan, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, color: Colors.white.withValues(alpha: 0.3), size: 60),
          const SizedBox(height: 16),
          Text('لم نجد نتائج مطابقة',
            style: GoogleFonts.cairo(color: Colors.white.withValues(alpha: 0.6), fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text('نتائج البحث', style: GoogleFonts.cairo(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.nebulaCyan.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                child: Text('${_results.length}',
                  style: GoogleFonts.poppins(color: AppColors.nebulaCyan, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: _results.length,
            itemBuilder: (context, index) {
              final song = _results[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                      ref.read(playbackProvider.notifier).setQueue(_results, startIndex: index);
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.8),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.surface, borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: AppColors.nebulaCyan.withValues(alpha: 0.3), width: 1.2),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    const Icon(Icons.auto_awesome_rounded, color: AppColors.nebulaCyan, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                          hintText: 'اكتب اسم أغنية أو فنان...',
                          hintStyle: GoogleFonts.cairo(color: Colors.white.withValues(alpha: 0.35), fontSize: 14),
                        ),
                        onSubmitted: (_) => _submitQuery(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _submitQuery,
              child: Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, gradient: AppColors.cosmicGradient,
                  boxShadow: [BoxShadow(color: AppColors.nebulaCyan.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 3))],
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
