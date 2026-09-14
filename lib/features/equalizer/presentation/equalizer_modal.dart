import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class EqualizerModal extends StatefulWidget {
  const EqualizerModal({super.key});

  @override
  State<EqualizerModal> createState() => _EqualizerModalState();
}

class _EqualizerModalState extends State<EqualizerModal> {
  String _activePreset = 'Cosmic Reverb 🌌';
  double _bass = 0.8;
  double _mid = 0.5;
  double _treble = 0.7;

  final List<String> _presets = [
    'Cosmic Reverb 🌌',
    'Bass Boost 🔊',
    'Vocal Clarity 🎤',
    'Starlight 3D 🪐',
    'Flat 🎧',
  ];

  void _selectPreset(String preset) {
    setState(() {
      _activePreset = preset;
      if (preset == 'Bass Boost 🔊') {
        _bass = 1.0; _mid = 0.4; _treble = 0.5;
      } else if (preset == 'Cosmic Reverb 🌌') {
        _bass = 0.8; _mid = 0.7; _treble = 0.9;
      } else if (preset == 'Vocal Clarity 🎤') {
        _bass = 0.3; _mid = 0.9; _treble = 0.8;
      } else if (preset == 'Starlight 3D 🪐') {
        _bass = 0.9; _mid = 0.8; _treble = 0.9;
      } else {
        _bass = 0.5; _mid = 0.5; _treble = 0.5;
      }
    });
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
          border: Border.all(
            color: AppColors.nebulaCyan.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.spaceViolet.withValues(alpha: 0.4),
              blurRadius: 30,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'المعادل الصوتي الفضائي',
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _presets.map((preset) {
                  final isSelected = _activePreset == preset;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(preset, style: GoogleFonts.cairo(color: Colors.white, fontSize: 12)),
                      selected: isSelected,
                      selectedColor: AppColors.nebulaCyan.withValues(alpha: 0.4),
                      backgroundColor: AppColors.surface,
                      onSelected: (_) => _selectPreset(preset),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            _buildSlider('البيس الكوني (Bass)', _bass, (val) => setState(() => _bass = val)),
            _buildSlider('الصوت المتوسط (Mids)', _mid, (val) => setState(() => _mid = val)),
            _buildSlider('الترددات العالية (Treble)', _treble, (val) => setState(() => _treble = val)),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.cairo(color: Colors.white70, fontSize: 13)),
            Text('${(value * 100).round()}%', style: GoogleFonts.poppins(color: AppColors.nebulaCyan, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: value,
          activeColor: AppColors.nebulaCyan,
          inactiveColor: Colors.white12,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
