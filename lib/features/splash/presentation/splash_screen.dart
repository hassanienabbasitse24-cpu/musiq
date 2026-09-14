import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/space_background.dart';
import '../../home/presentation/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _waveController;
  late AnimationController _pulseController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _glowAnimation;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // Main entrance animation (1.2 seconds)
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Continuous wave bars animation
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    // Gentle breathing halo pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _scaleAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.2, 0.85, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<double>(begin: 24, end: 0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.2, end: 0.7).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _mainController.forward();

    // Quick, snappy intro: navigate after 1.9 seconds
    Future.delayed(const Duration(milliseconds: 1900), () {
      _goToHome();
    });
  }

  void _goToHome() {
    if (!mounted || _navigated) return;
    _navigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    _waveController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _goToHome, // Allow instant tap to skip
        child: SpaceBackground(
          child: SafeArea(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _mainController,
                _waveController,
                _pulseController,
              ]),
              builder: (context, _) {
                return Stack(
                  children: [
                    // Center Content (Logo + Brand + Subtitles)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildGlowingLogo(),
                          const SizedBox(height: 28),
                          _buildBrandTypography(),
                        ],
                      ),
                    ),

                    // Bottom Soundwave Spectrum & Loading Glow
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 40,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildSoundWaveBars(),
                          const SizedBox(height: 16),
                          Text(
                            'المجرة الموسيقية في انتظارك',
                            style: GoogleFonts.cairo(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlowingLogo() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Expanding Ripple Ring
          Container(
            width: 140 + (_pulseController.value * 20),
            height: 140 + (_pulseController.value * 20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.nebulaCyan.withValues(
                  alpha: (1.0 - _pulseController.value) * 0.4,
                ),
                width: 1.5,
              ),
            ),
          ),

          // Glowing Aura
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.nebulaCyan.withValues(alpha: _glowAnimation.value),
                  blurRadius: 40,
                  spreadRadius: 6,
                ),
                BoxShadow(
                  color: AppColors.spaceViolet.withValues(alpha: _glowAnimation.value * 0.8),
                  blurRadius: 60,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),

          // Glassmorphic Logo Shell
          Container(
            width: 110,
            height: 110,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.nebulaCyan.withValues(alpha: 0.5),
                  AppColors.spaceViolet.withValues(alpha: 0.6),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.8,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/app_icon.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.spaceViolet,
                  child: const Icon(
                    Icons.music_note_rounded,
                    size: 54,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandTypography() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Transform.translate(
        offset: Offset(0, _slideAnimation.value),
        child: Column(
          children: [
            // Holographic Shimmer MUSIQ Title
            ShaderMask(
              shaderCallback: (bounds) {
                return const LinearGradient(
                  colors: [
                    AppColors.nebulaCyan,
                    AppColors.starlightBlue,
                    Color(0xFFE0C3FC),
                    AppColors.nebulaCyan,
                  ],
                  stops: [0.0, 0.4, 0.7, 1.0],
                ).createShader(bounds);
              },
              child: Text(
                'MUSIQ',
                style: GoogleFonts.orbitron(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Arabic Futuristic Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: AppColors.spaceViolet.withValues(alpha: 0.25),
                border: Border.all(
                  color: AppColors.nebulaCyan.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Text(
                'موزيك الفضائي',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.nebulaCyan,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Micro Subtitle
            Text(
              'AI-POWERED COSMIC SOUND',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.45),
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundWaveBars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(9, (index) {
        final sine = sin((_waveController.value * 2 * pi) + (index * 0.7));
        final height = 8 + (sine * 0.5 + 0.5) * 22;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 3.5,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.nebulaCyan,
                AppColors.spaceViolet,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.nebulaCyan.withValues(alpha: 0.4),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        );
      }),
    );
  }
}
