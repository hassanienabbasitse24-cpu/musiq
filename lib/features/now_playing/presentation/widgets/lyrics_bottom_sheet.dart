import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

class LyricsBottomSheet extends StatelessWidget {
  const LyricsBottomSheet({super.key});

  static const List<_LyricLine> _lyrics = [
    _LyricLine(time: '0:00', text: 'حبيبي يا حبيبي', en: 'My love, oh my love'),
    _LyricLine(time: '0:08', text: '.intro music plays', en: ''),
    _LyricLine(time: '0:15', text: 'عيوني في عيونك', en: 'My eyes are in your eyes'),
    _LyricLine(time: '0:22', text: 'My heart beats for you', en: ''),
    _LyricLine(time: '0:30', text: 'قلبي بين ايديك', en: 'My heart is in your hands'),
    _LyricLine(time: '0:38', text: 'والدنيا بحالها', en: 'And the whole world'),
    _LyricLine(time: '0:45', text: 'enti helwa keda', en: 'You are beautiful like this'),
    _LyricLine(time: '0:52', text: 'حاسس بجمال الحب', en: 'Feeling the magic of love'),
    _LyricLine(time: '1:00', text: 'الليلة ليلتنا', en: 'Tonight is our night'),
    _LyricLine(time: '1:08', text: 'You light up my world', en: ''),
    _LyricLine(time: '1:15', text: 'مش عايز غيرك', en: 'I do not want anyone but you'),
    _LyricLine(time: '1:22', text: 'عمري معاك حلو', en: 'My life is beautiful with you'),
    _LyricLine(time: '1:30', text: 'habibi ya habibi', en: ''),
    _LyricLine(time: '1:38', text: 'بنتظار لحظة', en: 'Waiting for a moment'),
    _LyricLine(time: '1:45', text: 'التقينا واعترفنا', en: 'We met and confessed'),
    _LyricLine(time: '1:52', text: 'I found my way to you', en: ''),
    _LyricLine(time: '2:00', text: 'خليك جنبي دايماً', en: 'Stay by my side always'),
    _LyricLine(time: '2:08', text: 'بنتكلم بلسان القلب', en: 'We speak the language of the heart'),
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.85),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(32),
            ),
            border: Border.all(
              color: AppColors.nebulaCyan.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.spaceViolet.withValues(alpha: 0.4),
                blurRadius: 30,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(32),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Column(
                children: [
                  _buildDragHandle(),
                  _buildHeader(),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      itemCount: _lyrics.length,
                      itemBuilder: (context, index) {
                        final line = _lyrics[index];
                        final isActive = index == 2;
                        return _buildLyricLine(line, isActive);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDragHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Container(
        width: 44,
        height: 5,
        decoration: BoxDecoration(
          color: AppColors.nebulaCyan.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Cosmic Lyrics',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'كلمات الأغنية',
            style: GoogleFonts.cairo(
              color: AppColors.nebulaCyan,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLyricLine(_LyricLine line, bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.nebulaCyan.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: isActive
            ? Border.all(
                color: AppColors.nebulaCyan.withValues(alpha: 0.5),
                width: 1,
              )
            : null,
      ),
      child: Row(
        children: [
          Text(
            line.time,
            style: GoogleFonts.poppins(
              color: isActive ? AppColors.nebulaCyan : Colors.white.withValues(alpha: 0.35),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.text,
                  style: GoogleFonts.cairo(
                    color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.65),
                    fontSize: isActive ? 18 : 15,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (line.en.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    line.en,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LyricLine {
  final String time;
  final String text;
  final String en;

  const _LyricLine({
    required this.time,
    required this.text,
    required this.en,
  });
}
