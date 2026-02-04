import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ornek_flutter_web/screens/dashboard/department_management_screen.dart';
import 'package:ornek_flutter_web/screens/dashboard/role_management_screen.dart';
import 'package:ornek_flutter_web/providers/user_provider.dart';
import 'package:ornek_flutter_web/providers/permission_provider.dart';
import 'package:ornek_flutter_web/models/user_permission_model.dart';
import 'package:ornek_flutter_web/services/auth_service.dart';
import 'test_screen.dart';

class ManagementScreen extends StatefulWidget {
  const ManagementScreen({super.key});

  @override
  State<ManagementScreen> createState() => _ManagementScreenState();
}

class _ManagementScreenState extends State<ManagementScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _particleController;
  late AnimationController _segmentController;
  final List<Offset> _particlePositions = [];
  final List<double> _particleSpeeds = [];
  final List<Color> _particleColors = [];
  
  @override
  void initState() {
    super.initState();
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    _segmentController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();
    
    _initializeParticles();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _particleController.dispose();
    _segmentController.dispose();
    super.dispose();
  }
  
  void _initializeParticles() {
    final random = Random();
    for (int i = 0; i < 50; i++) {
      _particlePositions.add(Offset(
        random.nextDouble(),
        random.nextDouble(),
      ));
      _particleSpeeds.add(0.1 + random.nextDouble() * 0.3);
      _particleColors.add([
        Colors.orange.withOpacity(0.3),
        Colors.blue.withOpacity(0.2),
        Colors.purple.withOpacity(0.25),
        Colors.teal.withOpacity(0.2),
      ][random.nextInt(4)]);
    }
  }
  
    void _showManagementAccessDialog(BuildContext context) {
    _searchController.clear(); // Önceki aramayı temizle
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF172A46),
              title: const Text(
                'Yönetim Paneli Erişimi',
                style: TextStyle(color: Colors.white),
              ),
              content: Container(
                width: 600,
                height: 500,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kullanıcılara yönetim paneli erişim yetkisi verin veya kaldırın:',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    // Arama kutusunu ekle
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Kullanıcı ara (isim veya email)...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                        prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: Colors.white.withOpacity(0.7)),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFF0A192F),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.blue),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {}); // Arama sonuçlarını güncelle
                      },
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Consumer2<UserProvider, PermissionProvider>(
                        builder: (context, userProvider, permissionProvider, child) {
                          if (userProvider.users.isEmpty) {
                            userProvider.fetchUsers();
                            return const Center(child: CircularProgressIndicator());
                          }

                          // Arama filtresini uygula
                          final filteredUsers = userProvider.users.where((user) {
                            final searchTerm = _searchController.text.toLowerCase();
                            if (searchTerm.isEmpty) return true;
                            
                            final username = (user.username ?? '').toLowerCase();
                            final email = user.email.toLowerCase();
                            
                            return username.contains(searchTerm) || email.contains(searchTerm);
                          }).toList();

                          if (filteredUsers.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 48,
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Arama kriterlerine uygun kullanıcı bulunamadı',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Sonuç sayısını göster
                              if (_searchController.text.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    '${filteredUsers.length} kullanıcı bulundu',
                                    style: TextStyle(
                                      color: Colors.blue.shade300,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: filteredUsers.length,
                                  itemBuilder: (context, index) {
                                    final user = filteredUsers[index];
                                    return _UserAccessCard(
                                      user: user,
                                      onToggle: (value) => _toggleManagementAccess(user.userId, value),
                                      searchTerm: _searchController.text, // Vurgulama için
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Kapat'),
                ),
              ],
            );
          },
        );
      },
    );
  }



  Future<void> _toggleManagementAccess(String userId, bool grant) async {
    try {
      final permissionProvider = Provider.of<PermissionProvider>(context, listen: false);
      
      if (grant) {
        await permissionProvider.addPermission(userId, PermissionTypes.managementPanelAccess);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kullanıcıya yönetim paneli erişimi verildi'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await permissionProvider.removePermission(userId, PermissionTypes.managementPanelAccess);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kullanıcının yönetim paneli erişimi kaldırıldı'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      
      // Eğer o anda aktif kullanıcının yetkisini kaldırıyorsak, AuthService'i yenile
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.refreshUserData();
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0F172A),
              const Color(0xFF1E293B),
              const Color(0xFF334155),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated particles
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: ParticlePainter(
                    particles: _particlePositions,
                    colors: _particleColors,
                    animation: _particleController.value,
                    speeds: _particleSpeeds,
                  ),
                  size: Size.infinite,
                );
              },
            ),
            // Circular segments
            AnimatedBuilder(
              animation: _segmentController,
              builder: (context, child) {
                return Positioned(
                  top: -100,
                  right: -100,
                  child: _buildCircularSegment(200, _segmentController.value),
                );
              },
            ),
            AnimatedBuilder(
              animation: _segmentController,
              builder: (context, child) {
                return Positioned(
                  bottom: -150,
                  left: -150,
                  child: _buildCircularSegment(300, -_segmentController.value),
                );
              },
            ),
            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Custom AppBar
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [Colors.orange.withOpacity(0.9), Colors.blue.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        'Yönetim Paneli',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Content
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        _buildManagementCard(
                          context: context,
                          icon: Icons.business,
                          title: 'Departman Yönetimi',
                          subtitle: 'Departmanları ve çalışan atamalarını yönetin.',
                          color: Colors.blue.withOpacity(0.8),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const DepartmentManagementScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildManagementCard(
                          context: context,
                          icon: Icons.people_outline,
                          title: 'Rol Yönetimi',
                          subtitle: 'Kullanıcı rollerini ve hiyerarşiyi yapılandırın.',
                          color: Colors.purple.withOpacity(0.8),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RoleManagementScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildManagementCard(
                          context: context,
                          icon: Icons.admin_panel_settings,
                          title: 'Yönetim Paneli Erişimi',
                          subtitle: 'Kullanıcılara yönetim paneli erişim yetkisi verin.',
                          color: Colors.green.withOpacity(0.8),
                          onTap: () {
                            _showManagementAccessDialog(context);
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildManagementCard(
                          context: context,
                          icon: Icons.bug_report,
                          title: 'Test Ekranı',
                          subtitle: 'Yeni kodları test edin',
                          color: Colors.orange.withOpacity(0.8),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const TestScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E293B).withOpacity(0.8),
            const Color(0xFF334155).withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.8),
                        color.withOpacity(0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: 28, color: Colors.white),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.6),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildCircularSegment(double size, double rotation) {
    return Transform.rotate(
      angle: rotation * 2 * pi,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.orange.withOpacity(0.1),
              Colors.blue.withOpacity(0.05),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

class ParticlePainter extends CustomPainter {
  final List<Offset> particles;
  final List<Color> colors;
  final double animation;
  final List<double> speeds;

  ParticlePainter({
    required this.particles,
    required this.colors,
    required this.animation,
    required this.speeds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < particles.length; i++) {
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;

      final dx = (particles[i].dx + animation * speeds[i]) % 1.0;
      final dy = (particles[i].dy + animation * speeds[i] * 0.5) % 1.0;

      canvas.drawCircle(
        Offset(dx * size.width, dy * size.height),
        2.0 + sin(animation * 2 * pi + i) * 1.0,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _UserAccessCard extends StatefulWidget {
  final dynamic user;
  final Function(bool) onToggle;
  final String? searchTerm;

  const _UserAccessCard({
    required this.user,
    required this.onToggle,
    this.searchTerm,
  });

  @override
  State<_UserAccessCard> createState() => _UserAccessCardState();
}

class _UserAccessCardState extends State<_UserAccessCard> {
  bool _hasAccess = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Build tamamlandıktan sonra veri çek
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAccess();
    });
  }

  Future<void> _checkAccess() async {
    if (!mounted) return;
    
    try {
      final permissionProvider = Provider.of<PermissionProvider>(context, listen: false);
      await permissionProvider.fetchUserPermissions(widget.user.userId);
      final hasAccess = permissionProvider.hasPermission(widget.user.userId, PermissionTypes.managementPanelAccess);
      
      if (mounted) {
        setState(() {
          _hasAccess = hasAccess;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasAccess = false;
          _isLoading = false;
        });
      }
    }
  }

  // Arama terimini vurgulama fonksiyonu
  Widget _buildHighlightedText(String text, String? searchTerm) {
    if (searchTerm == null || searchTerm.isEmpty) {
      return Text(text, style: const TextStyle(color: Colors.white));
    }

    final searchTermLower = searchTerm.toLowerCase();
    final textLower = text.toLowerCase();
    
    if (!textLower.contains(searchTermLower)) {
      return Text(text, style: const TextStyle(color: Colors.white));
    }

    final startIndex = textLower.indexOf(searchTermLower);
    final endIndex = startIndex + searchTerm.length;

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: text.substring(0, startIndex),
            style: const TextStyle(color: Colors.white),
          ),
          TextSpan(
            text: text.substring(startIndex, endIndex),
            style: const TextStyle(
              color: Colors.yellow,
              fontWeight: FontWeight.bold,
              backgroundColor: Colors.orange,
            ),
          ),
          TextSpan(
            text: text.substring(endIndex),
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF0A192F),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: (widget.user.avatarUrl != null && widget.user.avatarUrl!.isNotEmpty)
              ? NetworkImage(widget.user.avatarUrl!)
              : null,
          child: (widget.user.avatarUrl == null || widget.user.avatarUrl!.isEmpty)
              ? const Icon(Icons.person)
              : null,
        ),
        title: _buildHighlightedText(
          widget.user.username ?? 'Bilinmeyen Kullanıcı',
          widget.searchTerm,
        ),
        subtitle: _buildHighlightedText(
          widget.user.email,
          widget.searchTerm,
        ),
        trailing: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Switch(
                value: _hasAccess,
                onChanged: (value) async {
                  setState(() {
                    _hasAccess = value; // Optimistic update
                  });
                  
                  // Asıl işlemi yap
                  try {
                    await widget.onToggle(value);
                  } catch (e) {
                    // Hata durumunda geri al
                    setState(() {
                      _hasAccess = !value;
                    });
                  }
                },
                activeColor: Colors.green,
                activeTrackColor: Colors.green.withOpacity(0.5),
                inactiveThumbColor: Colors.grey,
                inactiveTrackColor: Colors.grey.withOpacity(0.3),
              ),
      ),
    );
  }
}