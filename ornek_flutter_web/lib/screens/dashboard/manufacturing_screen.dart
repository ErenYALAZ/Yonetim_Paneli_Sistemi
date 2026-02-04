import 'package:flutter/material.dart';
import 'package:ornek_flutter_web/providers/job_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart'; // AuthService'i import ediyoruz

class ManufacturingScreen extends StatefulWidget {
  const ManufacturingScreen({super.key});

  @override
  State<ManufacturingScreen> createState() => _ManufacturingScreenState();
}

class _ManufacturingScreenState extends State<ManufacturingScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>>? _users;

  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<Color?> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _fetchUsers();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _glowAnimation = ColorTween(
      begin: Colors.yellow.shade600,
      end: Colors.transparent,
    ).animate(CurvedAnimation(parent: _controller!, curve: Curves.easeInOut));
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
        CurvedAnimation(parent: _controller!, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    try {
      final response =
          await Supabase.instance.client.from('profiles').select('id, username');
      if (mounted) {
        setState(() {
          _users = (response as List).cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Kullanıcılar yüklenemedi: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _assignJob(int jobId, String userId, String userName) async {
    try {
      await Supabase.instance.client
          .from('jobs')
          .update({'assigned_to': userId, 'assigned_to_name': userName})
          .eq('id', jobId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İş, $userName kullanıcısına atandı.'), backgroundColor: Colors.blue),
      );
      
      // Cache'i temizle ve zorla yenile
      final jobProvider = context.read<JobProvider>();
      jobProvider.invalidateCache();
      await jobProvider.fetchAllJobs(forceRefresh: true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İş atanamadı: $e'), backgroundColor: Colors.red),
      );
    }
  }
  
  Future<void> _completeJob(int jobId) async {
     try {
      await Supabase.instance.client
          .from('jobs')
          .update({'status': 'Onay Bekliyor'})
          .eq('id', jobId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İş, onay için gönderildi!'), backgroundColor: Colors.orange),
      );
      
      // Cache'i temizle ve zorla yenile
      final jobProvider = context.read<JobProvider>();
      jobProvider.invalidateCache();
      await jobProvider.fetchAllJobs(forceRefresh: true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İşin durumu güncellenemedi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _refreshJobs() {
    final jobProvider = context.read<JobProvider>();
    jobProvider.invalidateCache();
    jobProvider.fetchAllJobs(forceRefresh: true);
  }
  
  void _showAssignUserDialog(Map<String, dynamic> job) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1A0B2E).withOpacity(0.95),
                  const Color(0xFF2D1B3D).withOpacity(0.9),
                  const Color(0xFF3E2A47).withOpacity(0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.2),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
              border: Border.all(
                color: const Color(0xFF8B5CF6).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [Colors.orange.withOpacity(0.9), Colors.red.withOpacity(0.8), Colors.pink.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    '"${job['title']}" için Kullanıcı Ata',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: _users == null
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _users!.length,
                          itemBuilder: (context, index) {
                            final user = _users![index];
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF8B5CF6).withOpacity(0.1),
                                    const Color(0xFFEC4899).withOpacity(0.05),
                                  ],
                                ),
                                border: Border.all(
                                  color: const Color(0xFF8B5CF6).withOpacity(0.2),
                                ),
                              ),
                              child: ListTile(
                                title: Text(
                                  user['username'] ?? 'İsimsiz Kullanıcı',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  _assignJob(job['id'], user['id'],
                                      user['username'] ?? 'İsimsiz Kullanıcı');
                                },
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white.withOpacity(0.6),
                                  size: 16,
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 24),
                _buildModernDialogButton(
                  text: 'İptal',
                  onPressed: () => Navigator.of(context).pop(),
                  isPrimary: false,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCompleteJobDialog(Map<String, dynamic> job) {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (!authService.isAdmin() && !authService.canManageManufacturing()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'İmalat işlemlerini tamamlama yetkiniz yok!',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (confirmContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A0B2E).withOpacity(0.95),
                const Color(0xFF2D1B3D).withOpacity(0.9),
                const Color(0xFF3E2A47).withOpacity(0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withOpacity(0.2),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
            border: Border.all(
              color: const Color(0xFF8B5CF6).withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [Colors.orange.withOpacity(0.9), Colors.red.withOpacity(0.8), Colors.pink.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Text(
                  'Onay',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '"${job['title']}" işini tamamlayıp onaya göndermek istediğinizden emin misiniz?',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildModernDialogButton(
                    text: 'Hayır',
                    onPressed: () => Navigator.of(confirmContext).pop(),
                    isPrimary: false,
                  ),
                  _buildModernDialogButton(
                    text: 'Evet',
                    onPressed: () {
                      Navigator.of(confirmContext).pop();
                      _completeJob(job['id']);
                    },
                    isPrimary: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernDialogButton({
    required String text,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: isPrimary
            ? LinearGradient(
                colors: [
                  const Color(0xFF8B5CF6),
                  const Color(0xFFEC4899),
                  const Color(0xFFF59E0B),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  const Color(0xFF374151).withOpacity(0.8),
                  const Color(0xFF4B5563).withOpacity(0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: const Color(0xFFEC4899).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0F0A1A), // Deep purple-black
              const Color(0xFF1A0B2E), // Dark purple
              const Color(0xFF2D1B3D), // Medium purple
              const Color(0xFF3E2A47), // Lighter purple
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [Colors.orange.withOpacity(0.9), Colors.red.withOpacity(0.8), Colors.pink.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                'İmalattaki Aktif İşler',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF8B5CF6).withOpacity(0.8),
                      const Color(0xFFEC4899).withOpacity(0.6),
                    ],
                  ),
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _refreshJobs,
                  tooltip: 'Yenile',
                ),
              ),
            ],
          ),
          body: Consumer<JobProvider>(
        builder: (context, jobProvider, child) {
          if (jobProvider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'İmalat verileri yükleniyor...',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }
          if (jobProvider.activeJobs.isEmpty) {
            return Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF8B5CF6).withOpacity(0.1),
                      const Color(0xFFEC4899).withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF8B5CF6).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.work_off,
                      size: 64,
                      color: Colors.white.withOpacity(0.6),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'İmalatta bekleyen aktif iş bulunmuyor.',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Yeni işler eklendiğinde burada görünecektir.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final jobs = List<Map<String, dynamic>>.from(jobProvider.activeJobs);
          // Kullanıcıya atanan işleri listenin en başına almak için sıralama
          if (currentUserId != null) {
            jobs.sort((a, b) {
              final aIsMine = a['assigned_to'] == currentUserId;
              final bIsMine = b['assigned_to'] == currentUserId;
              if (aIsMine && !bIsMine) return -1; // a'yı öne al
              if (!aIsMine && bIsMine) return 1;  // b'yi öne al
              // Diğer durumlarda mevcut sıralamayı koru (created_at)
              return DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at']));
            });
          }

          final double screenWidth = MediaQuery.of(context).size.width;
          // Kart genişliğini yaklaşık 220px olarak hedefleyerek ekrana sığacak sütun sayısını hesapla
          final int crossAxisCount = (screenWidth / 220).floor().clamp(1, 5);

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1, // Kare kartlar için
            ),
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];
              return _buildJobCard(job, currentUserId);
            },
          );
        },
          ),
        ),
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job, String? currentUserId) {
    final assignedToId = job['assigned_to'];
    final isAssignedToMe = currentUserId != null && assignedToId == currentUserId;
    final authService = Provider.of<AuthService>(context, listen: false);

    if (isAssignedToMe && _controller != null && _glowAnimation != null) {
      // Animated card for jobs assigned to the current user
      return AnimatedBuilder(
        animation: _controller!,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF8B5CF6).withOpacity(0.2),
                    const Color(0xFFEC4899).withOpacity(0.15),
                    const Color(0xFFF59E0B).withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withOpacity(0.8),
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _glowAnimation!.value ?? Colors.transparent,
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
        child: _buildCardContent(job, isAssignedToMe: isAssignedToMe, authService: authService),
      );
    } else {
      // Diğer tüm işler için modern kart tasarımı
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF8B5CF6).withOpacity(0.1),
              const Color(0xFFEC4899).withOpacity(0.05),
              const Color(0xFFF59E0B).withOpacity(0.03),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: const Color(0xFF8B5CF6).withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _buildCardContent(job, isAssignedToMe: isAssignedToMe, authService: authService),
      );
    }
  }

  Widget _buildCardContent(Map<String, dynamic> job, {required bool isAssignedToMe, required AuthService authService}) {
    final assignedTo = job['assigned_to_name'];
    
    final Color nameColor;
    final FontWeight nameFontWeight;

    if (isAssignedToMe) {
      // Kullanıcının kendi işi
      nameColor = const Color(0xFFF59E0B);
      nameFontWeight = FontWeight.bold;
    } else if (assignedTo != null) {
      // Başkasına atanmış iş
      nameColor = Colors.white.withOpacity(0.8);
      nameFontWeight = FontWeight.normal;
    } else {
      // Atanmamış iş
      nameColor = Colors.white.withOpacity(0.5);
      nameFontWeight = FontWeight.normal;
    }

    // Sadece kullanıcıya atanan işlerin başlığını vurgula
    final titleColor = isAssignedToMe ? const Color(0xFFEC4899) : Colors.white.withOpacity(0.9);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Üst Kısım: Başlık ve Firma
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job['title'],
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              if (job['company_name'] != null)
                Text(
                  job['company_name'],
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Orta Kısım: Atanan Kullanıcı
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF8B5CF6).withOpacity(0.2),
                  const Color(0xFFEC4899).withOpacity(0.1),
                ],
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person_outline,
                  color: Colors.white.withOpacity(0.7),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    assignedTo ?? 'Henüz Atanmadı',
                    style: GoogleFonts.poppins(
                      fontStyle: assignedTo == null ? FontStyle.italic : FontStyle.normal,
                      color: nameColor,
                      fontWeight: nameFontWeight,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Alt Kısım: Butonlar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Sadece admin kullanıcı atayabilir
              if (authService.isAdmin())
                _buildModernButton(
                  text: 'Ata',
                  onPressed: () => _showAssignUserDialog(job),
                  isPrimary: false,
                ),
              // İmalat yetkisi olanlar işi tamamlayıp onaya gönderebilir
              if (authService.isAdmin() || authService.canManageManufacturing())
                _buildModernButton(
                  text: 'Bitti',
                  onPressed: () => _showCompleteJobDialog(job),
                  isPrimary: true,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernButton({
    required String text,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: isPrimary
            ? LinearGradient(
                colors: [
                  const Color(0xFF10B981), // Green
                  const Color(0xFF059669), // Darker green
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  const Color(0xFF8B5CF6).withOpacity(0.8),
                  const Color(0xFFEC4899).withOpacity(0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        boxShadow: [
          BoxShadow(
            color: isPrimary 
                ? const Color(0xFF10B981).withOpacity(0.4)
                : const Color(0xFF8B5CF6).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}