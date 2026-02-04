import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import '../../providers/announcement_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/department_provider.dart';
import '../../services/auth_service.dart';
import '../main_layout_screen.dart';

class Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _particleController;
  late AnimationController _segmentController;
  List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900), // Animasyon süresini biraz uzattık
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4), // Daha aşağıdan başlasın
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // Performans için particle animasyonlarını daha az sıklıkta çalıştır
    _particleController = AnimationController(
      duration: const Duration(seconds: 30), // Daha yavaş
      vsync: this,
    )..repeat();
    
    _segmentController = AnimationController(
      duration: const Duration(seconds: 20), // Daha yavaş
      vsync: this,
    )..repeat();
    
    // Particle sayısını azalt
    _initializeParticles();

    // initState içinde verileri yüklemek, build metodunun tekrar tekrar çağrılmasını önler
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Provider'ları dinlemeden verileri çek
        context.read<JobProvider>().fetchPendingJobs();
        context.read<AnnouncementProvider>().fetchAnnouncements();
        _controller.forward();
      }
    });
  }

  void _initializeParticles() {
    final random = Random();
    _particles = List.generate(15, (index) { // Particle sayısını yarıya düşür
      return Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: random.nextDouble() * 4 + 1,
        speed: random.nextDouble() * 0.5 + 0.1,
        opacity: random.nextDouble() * 0.6 + 0.2,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _particleController.dispose();
    _segmentController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedItem(Widget child, {required double intervalStart}) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _controller,
        curve: Interval(intervalStart, 1.0, curve: Curves.easeOut),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.5),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: Interval(intervalStart, 1.0, curve: Curves.easeOut),
        )),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final userName = currentUser?.userMetadata?['full_name'] as String? ??
        currentUser?.email ??
        'Kullanıcı';
    
    // Verileri context.watch ile dinleyerek UI'ın güncel kalmasını sağla
    final pendingJobCount = context.watch<JobProvider>().pendingJobs.length;
    final unreadAnnouncements = context.watch<AnnouncementProvider>().unreadCount;

    return Scaffold(
      backgroundColor: Colors.transparent, // Arka planı transparan yap
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: 700), // Panel genişliğini artırdık
                child: Container(
                  padding: const EdgeInsets.all(32), // İç boşluğu artırdık
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF2D1B3D),
                        Color(0xFF3E2A47),
                        Color(0xFF4A3356),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF8B5CF6).withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withOpacity(0.2),
                        blurRadius: 25,
                        spreadRadius: 5,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Hoş Geldiniz Mesajı
                      _buildAnimatedItem(
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.shield_moon,
                                color: Colors.amber, size: 40),
                            const SizedBox(width: 20),
                            Flexible(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hoş Geldiniz,',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey.shade300,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    userName,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        intervalStart: 0.0,
                      ),
                      
                      const SizedBox(height: 28),
                      
                      // Ayırıcı
                      _buildAnimatedItem(
                        Divider(
                          color: Colors.white.withOpacity(0.15),
                          thickness: 1,
                          indent: 20,
                          endIndent: 20,
                        ),
                        intervalStart: 0.2,
                      ),
                      
                      const SizedBox(height: 28),

                      // 2. Hızlı İstatistikler
                      _buildAnimatedItem(
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatItem(
                              context,
                              icon: Icons.pending_actions,
                              label: 'Onay Bekleyen',
                              count: pendingJobCount,
                              color: Colors.orange.shade400,
                              onTap: () {
                                // MainLayoutScreen'deki state'i güncelle
                                MainLayoutScreen.of(context)?.onItemTapped(5);
                              }
                            ),
                            _buildStatItem(
                              context,
                              icon: Icons.campaign,
                              label: 'Yeni Duyuru',
                              count: unreadAnnouncements,
                              color: Colors.blue.shade400,
                               onTap: () {
                                MainLayoutScreen.of(context)?.onItemTapped(1);
                              }
                            ),
                          ],
                        ),
                        intervalStart: 0.4,
                      ),
                      

                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return _StatItemWidget(
      icon: icon,
      label: label,
      count: count,
      color: color,
      onTap: onTap,
    );
  }
}

class _StatItemWidget extends StatefulWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final VoidCallback onTap;

  const _StatItemWidget({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  State<_StatItemWidget> createState() => _StatItemWidgetState();
}

class _StatItemWidgetState extends State<_StatItemWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..scale(_isHovered ? 1.05 : 1.0),
          child: Column(
                children: [
                  Container(
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(
                       shape: BoxShape.circle,
                       gradient: LinearGradient(
                         colors: _isHovered ? [
                           const Color(0xFF8B5CF6).withOpacity(0.4),
                           const Color(0xFFEC4899).withOpacity(0.3),
                         ] : [
                           const Color(0xFF8B5CF6).withOpacity(0.2),
                           const Color(0xFFEC4899).withOpacity(0.15),
                         ],
                         begin: Alignment.topLeft,
                         end: Alignment.bottomRight,
                       ),
                       border: Border.all(
                         color: _isHovered 
                           ? const Color(0xFF8B5CF6).withOpacity(0.7)
                           : const Color(0xFF8B5CF6).withOpacity(0.4),
                         width: _isHovered ? 2.0 : 1.5,
                       ),
                       boxShadow: [
                         BoxShadow(
                           color: const Color(0xFF8B5CF6).withOpacity(_isHovered ? 0.2 : 0.1),
                           blurRadius: _isHovered ? 12 : 8,
                           offset: Offset(0, _isHovered ? 4 : 2),
                         ),
                       ],
                     ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(widget.icon, color: const Color(0xFF8B5CF6), size: 28),
                        if (widget.count > 0)
                          Positioned(
                            top: -8,
                            right: -8,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFFEF4444),
                                    const Color(0xFFDC2626),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFEF4444).withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                widget.count.toString(),
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.label,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF94A3B8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ),
    );
  }
}