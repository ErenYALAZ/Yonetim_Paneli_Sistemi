import 'package:flutter/material.dart';
import 'package:ornek_flutter_web/services/auth_service.dart';
import 'package:provider/provider.dart';
import '../providers/job_provider.dart';

class ApprovalScreen extends StatefulWidget {
  const ApprovalScreen({super.key});

  @override
  State<ApprovalScreen> createState() => _ApprovalScreenState();
}

class _ApprovalScreenState extends State<ApprovalScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<Color?> _glowAnimation;

  @override
  void initState() {
    super.initState();
    print("🔄 ApprovalScreen: initState BAŞLADI - JobProvider'dan veri alınacak");

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _glowAnimation = ColorTween(
      begin: Colors.orange.shade600,
      end: Colors.transparent,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Provider'ı tetikle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("⚡ ApprovalScreen: PostFrameCallback BAŞLADI");
      try {
        final jobProvider = Provider.of<JobProvider>(context, listen: false);
        print("✅ ApprovalScreen: JobProvider alındı - Pending Jobs: ${jobProvider.pendingJobs.length}");
        print("🗂️ ApprovalScreen: Mevcut pendingJobs içeriği: ${jobProvider.pendingJobs}");
        jobProvider.fetchPendingJobs();
        print("🔄 ApprovalScreen: fetchPendingJobs çağrıldı");
      } catch (e) {
        print("❌ ApprovalScreen: PostFrameCallback hatası: $e");
      }
    });
    
    print("✅ ApprovalScreen: initState TAMAMLANDI");
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _approveJob(int jobId) async {
    print("🚀 APPROVAL SCREEN: _approveJob çağrıldı, jobId: $jobId");
    
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    
    print("🚀 APPROVAL SCREEN: JobProvider alındı, approveJob çağrılıyor...");
    final success = await jobProvider.approveJob(jobId);
    
    print("🚀 APPROVAL SCREEN: approveJob sonucu: $success");
    
    if (!mounted) return;
    
    if (success) {
      print("🚀 APPROVAL SCREEN: Başarılı snackbar gösteriliyor");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İş başarıyla onaylandı ve bitmiş işlere taşındı.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      print("🚀 APPROVAL SCREEN: Başarısız snackbar gösteriliyor");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İş onaylanamadı. Lütfen tekrar deneyin.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showApproveJobDialog(Map<String, dynamic> job) {
    showDialog(
      context: context,
      builder: (confirmContext) => AlertDialog(
        title: const Text('Onay'),
        content: Text('"${job['title']}" işini onaylamak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(confirmContext).pop(),
            child: const Text('Hayır'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(confirmContext).pop();
              _approveJob(job['id']);
            },
            child: const Text('Evet'),
          ),
        ],
      ),
    );
  }

  void _refreshJobs() {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    jobProvider.invalidateCache();
    jobProvider.fetchAllJobs(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Onay Bekleyen İşler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshJobs,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: Consumer<JobProvider>(
        builder: (context, jobProvider, child) {
          print("🚀 ApprovalScreen: Consumer TETIKLENDI!");
              // print("📊 ApprovalScreen: JobProvider durumu - isLoading: ${jobProvider.isLoading}");
    // print("📊 ApprovalScreen: PendingJobs sayısı: ${jobProvider.pendingJobs.length}");
          print("🗂️ ApprovalScreen: PendingJobs içeriği: ${jobProvider.pendingJobs}");
          
          if (jobProvider.pendingJobs.isNotEmpty) {
            print("🔍 ApprovalScreen: İlk iş detayı:");
            final firstJob = jobProvider.pendingJobs.first;
            print("   - ID: ${firstJob['id']}");
            print("   - Title: ${firstJob['title']}");
            print("   - Status: '${firstJob['status']}'");
            print("   - Company: ${firstJob['company_name']}");
            print("   - Assigned: ${firstJob['assigned_to_name']}");
          }
          
          if (jobProvider.isLoading) {
            print("⏳ ApprovalScreen: Loading gösteriliyor");
            return const Center(child: CircularProgressIndicator());
          }

          final pendingJobs = jobProvider.pendingJobs;
          print("📝 ApprovalScreen: Final pendingJobs assignment - uzunluk: ${pendingJobs.length}");

          if (pendingJobs.isEmpty) {
            print("❌ ApprovalScreen: PendingJobs BOŞ - 'Onay bekleyen iş bulunmuyor' mesajı gösteriliyor");
            return const Center(
              child: Text(
                'Onay bekleyen iş bulunmuyor.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          print("✅ ApprovalScreen: GridView oluşturuluyor - ${pendingJobs.length} iş için");
          final double screenWidth = MediaQuery.of(context).size.width;
          // Kart genişliğini yaklaşık 220px olarak hedefleyerek ekrana sığacak sütun sayısını hesapla
          final int crossAxisCount = (screenWidth / 220).floor().clamp(1, 5);
          print("📐 ApprovalScreen: Grid crossAxisCount: $crossAxisCount");

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1, // Kare kartlar için
            ),
            itemCount: pendingJobs.length,
            itemBuilder: (context, index) {
              final job = pendingJobs[index];
              print("🃏 ApprovalScreen: Kart $index oluşturuluyor - Job: ${job['title']}");
              return _buildJobCard(job);
            },
          );
        },
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Onay bekleyen tüm işler için animasyon
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Card(
            elevation: 8,
            shadowColor: _glowAnimation.value,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: const Color(0xFF3B82F6),
                width: 2,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1E293B).withOpacity(0.9),
                    const Color(0xFF0F172A).withOpacity(0.7),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Başlık
                    Text(
                      job['title'] ?? 'Başlıksız İş',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    // Şirket adı
                    if (job['company_name'] != null) ...[
                      Row(
                        children: [
                          Icon(Icons.business, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              job['company_name'],
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    
                    // Tamamlayan kişi
                    if (job['assigned_to_name'] != null) ...[
                      Row(
                        children: [
                          Icon(Icons.person, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Tamamlayan: ${job['assigned_to_name']}',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],

                    const Spacer(),
                    
                    // Durum etiketi
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E40AF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Onay Bekliyor',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                                                  ),
                        ),
                      );
                        } else {
                          // print("❌ ONAY BUTONU GÖSTERİLMİYOR - Job ID: ${job['id']}");
                          return const SizedBox.shrink();
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    
                    // Onayla butonu - SADECE ADMIN VE MANAGER
                    if (authService.isAdmin() || authService.isManager())
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showApproveJobDialog(job),
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('Onayla'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}