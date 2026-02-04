import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ornek_flutter_web/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import '../../providers/job_provider.dart';

class ControlPanelScreen extends StatefulWidget {
  const ControlPanelScreen({super.key});

  @override
  State<ControlPanelScreen> createState() => _ControlPanelScreenState();
}

class _ControlPanelScreenState extends State<ControlPanelScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _particleController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    _animationController.forward();
    // Provider'ı başlat - sadece cache yoksa veri çek
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final jobProvider = Provider.of<JobProvider>(context, listen: false);
      jobProvider.fetchAllJobs(); // Cache kontrolü içinde yapılıyor
    });
  }

  Future<void> _addJob(String title, String status, String companyName) async {
    // Yetki kontrolü
    final authService = Provider.of<AuthService>(context, listen: false);
    if (!authService.isAdmin() && !authService.canManageControlPanel()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu işlem için yetkiniz yok!'), backgroundColor: Colors.red),
      );
      return;
    }
    
    try {
      // Saha departmanının gerçek ID'sini al
      final sahaDepResponse = await Supabase.instance.client
          .from('departments')
          .select('id')
          .eq('name', 'Saha')
          .single();
      
      final sahaDepId = sahaDepResponse['id'];
      
      await Supabase.instance.client.from('jobs').insert({
        'title': title,
        'status': status,
        'company_name': companyName.isNotEmpty ? companyName : null,
        'department_id': sahaDepId,
        'assigned_to': Supabase.instance.client.auth.currentUser?.id,
      });
      
      print('🔧 Saha departmanı için yeni iş oluşturuldu: $title (Departman ID: $sahaDepId)');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yeni iş başarıyla eklendi!'), backgroundColor: Colors.green),
      );
      
      // Cache'i invalidate et ve provider'ı güncelle
      final jobProvider = Provider.of<JobProvider>(context, listen: false);
      jobProvider.invalidateCache();
      jobProvider.fetchAllJobs(forceRefresh: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İş eklenemedi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showDeleteJobDialog(Map<String, dynamic> job) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1A0B2E).withOpacity(0.95), // Dark purple
                  const Color(0xFF2D1B3D).withOpacity(0.9),  // Medium purple
                  const Color(0xFF3E2A47).withOpacity(0.85), // Lighter purple
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
                Icon(
                  Icons.warning_amber_rounded,
                  size: 48,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: 16),
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [Colors.red.withOpacity(0.9), Colors.orange.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    'İşi Sil',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '"${job['title']}" adlı işi silmek istediğinizden emin misiniz?',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Bu işlem geri alınamaz.',
                  style: GoogleFonts.poppins(
                    color: Colors.red.withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildModernDialogButton(
                      text: 'İptal',
                      onPressed: () => Navigator.of(context).pop(),
                      isPrimary: false,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        gradient: LinearGradient(
                          colors: [
                            Colors.red.shade400,
                            Colors.red.shade600,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await _deleteJob(job['id']);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          'Sil',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteJob(int jobId) async {
    try {
      final jobProvider = Provider.of<JobProvider>(context, listen: false);
      await jobProvider.deleteJobs([jobId]);
      
      // Cache'i temizle ve verileri yenile
      jobProvider.invalidateCache();
      await jobProvider.fetchAllJobs(forceRefresh: true);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İş başarıyla silindi.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İş silinirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddJobDialog() {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final companyController = TextEditingController();
    String status = 'Aktif'; // Varsayılan durum

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
                  const Color(0xFF1A0B2E).withOpacity(0.95), // Dark purple
                  const Color(0xFF2D1B3D).withOpacity(0.9),  // Medium purple
                  const Color(0xFF3E2A47).withOpacity(0.85), // Lighter purple
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
            child: Form(
              key: formKey,
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
                      'Yeni İş Ekle',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildModernTextField(
                    controller: titleController,
                    label: 'İş Başlığı',
                    maxLength: 256,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen bir başlık girin.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildModernTextField(
                    controller: companyController,
                    label: 'Şirket Adı (İsteğe Bağlı)',
                    maxLength: 256,
                  ),
                  const SizedBox(height: 20),
                  Container(
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
                    child: DropdownButtonFormField<String>(
                      value: status,
                      decoration: InputDecoration(
                        labelText: 'Durum',
                        labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                      dropdownColor: const Color(0xFF2D1B3D),
                      style: const TextStyle(color: Colors.white),
                      items: ['Aktif', 'Bitmiş']
                          .map((label) => DropdownMenuItem(
                                value: label,
                                child: Text(label, style: const TextStyle(color: Colors.white)),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) status = value;
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildModernDialogButton(
                        text: 'İptal',
                        onPressed: () => Navigator.of(context).pop(),
                        isPrimary: false,
                      ),
                      _buildModernDialogButton(
                        text: 'Kaydet',
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            _addJob(
                              titleController.text.trim(),
                              status,
                              companyController.text.trim(),
                            );
                            Navigator.of(context).pop();
                          }
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
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

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
        child: Stack(
          children: [
            // Animated background particles
            ...List.generate(25, (index) => _buildParticle(index)),
            // Circular segments
            ...List.generate(12, (index) => _buildCircularSegment(index)),
            // Main content
            _buildMainContent(authService),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(AuthService authService) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: (authService.isAdmin() || authService.canManageControlPanel())
          ? Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF8B5CF6), // Purple
                      const Color(0xFFEC4899), // Pink
                      const Color(0xFFF59E0B), // Amber
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: const Color(0xFFEC4899).withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: FloatingActionButton(
                  onPressed: _showAddJobDialog,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  tooltip: 'Yeni İş Ekle',
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                ),
              ).animate().scale(delay: 800.ms, duration: 600.ms)
          : null, // Admin değilse butonu gösterme
      body: Consumer<JobProvider>(
        builder: (context, jobProvider, child) {
          if (jobProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Veriler yükleniyor...'),
                ],
              ),
            );
          }

          final activeJobs = jobProvider.activeJobs;
          final finishedJobs = jobProvider.completedJobs;
          final pendingJobs = jobProvider.pendingJobs;

          if (activeJobs.isEmpty && finishedJobs.isEmpty && pendingJobs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.work_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Gösterilecek iş verisi bulunamadı.'),
                  SizedBox(height: 8),
                  Text('Lütfen bir tane ekleyin.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final jobStats = {
            'Aktif': activeJobs.length,
            'Bitmiş': finishedJobs.length,
            'Onay Bekliyor': pendingJobs.length,
          };
          final totalJobs = jobStats.values.fold(0, (sum, item) => sum + item);
          final chartData = jobStats.entries
              .where((entry) => entry.value > 0) // Grafikte sadece 0'dan büyük olanları göster
              .map((entry) {
            return _ChartData(entry.key, entry.value.toDouble());
          }).toList();

          // Platforma göre layout seçimi
          bool isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

          if (isMobile) {
            // MOBİL/ANDROID GÖRÜNÜMÜ
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Aktif İş Özeti (Grafik)
                  Text(
                    'Aktif İş Özeti',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 300, // Grafik için sabit bir yükseklik
                    child: chartData.isEmpty 
                        ? const Center(child: Text('Veri bulunmuyor'))
                        : SfCircularChart(
                            enableMultiSelection: false,
                            legend: const Legend(
                                isVisible: true,
                                overflowMode: LegendItemOverflowMode.wrap),
                            series: <CircularSeries>[
                              DoughnutSeries<_ChartData, String>(
                                dataSource: chartData,
                                xValueMapper: (_ChartData data, _) => data.x,
                                yValueMapper: (_ChartData data, _) => data.y,
                                pointColorMapper: (_ChartData data, _) {
                                  switch (data.x) {
                                    case 'Aktif':
                                      return Colors.green.shade400;
                                    case 'Bitmiş':
                                      return Colors.blue.shade400;
                                    case 'Onay Bekliyor':
                                      return Colors.orange.shade400;
                                    default:
                                      return Colors.grey;
                                  }
                                },
                                dataLabelMapper: (_ChartData data, _) {
                                  final double percentage = totalJobs > 0
                                      ? (data.y / totalJobs * 100)
                                      : 0;
                                  return '${data.y.toInt()} (${percentage.toStringAsFixed(0)}%)';
                                },
                                dataLabelSettings: const DataLabelSettings(
                                  isVisible: true,
                                  textStyle: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red),
                                ),
                                innerRadius: '70%',
                                animationDuration: 800,
                              )
                            ],
                          ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Aktif İşler Listesi
                  Text('Aktif İşler',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  _buildJobListWidget(activeJobs, Colors.green.shade400),
                  
                  const SizedBox(height: 16),

                  // Bitmiş İşler Listesi
                  Text('Bitmiş İşler',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  _buildJobListWidget(finishedJobs, Colors.blue.shade400),
                  
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Departman Bazlı İş Takibi
                  Text('Departman Bazlı İş Takibi',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('Onaylanan işlerin departmanlara göre dağılımı',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      )),
                  const SizedBox(height: 16),
                  _buildDepartmentChart(jobProvider),
                ],
              ),
            );
          } else {
            // WEB/MASAÜSTÜ GÖRÜNÜMÜ (Mevcut kod)
            return Row(
              children: [
                Expanded(
                  flex: 2, // Grafik biraz daha büyük olsun
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Aktif İş Özeti',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: chartData.isEmpty 
                              ? const Center(child: Text('Veri bulunmuyor'))
                              : SfCircularChart(
                                  enableMultiSelection: false,
                                  legend: const Legend(
                                      isVisible: true,
                                      overflowMode: LegendItemOverflowMode.wrap),
                                  series: <CircularSeries>[
                                    DoughnutSeries<_ChartData, String>(
                                      dataSource: chartData,
                                      xValueMapper: (_ChartData data, _) => data.x,
                                      yValueMapper: (_ChartData data, _) => data.y,
                                      pointColorMapper: (_ChartData data, _) {
                                        switch (data.x) {
                                          case 'Aktif':
                                            return Colors.green.shade400;
                                          case 'Bitmiş':
                                            return Colors.blue.shade400;
                                          case 'Onay Bekliyor':
                                            return Colors.orange.shade400;
                                          default:
                                            return Colors.grey;
                                        }
                                      },
                                      dataLabelMapper: (_ChartData data, _) {
                                        final double percentage = totalJobs > 0
                                            ? (data.y / totalJobs * 100)
                                            : 0;
                                        return '${data.y.toInt()} (${percentage.toStringAsFixed(0)}%)';
                                      },
                                      dataLabelSettings: const DataLabelSettings(
                                        isVisible: true,
                                        textStyle: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red),
                                      ),
                                      innerRadius: '70%',
                                      animationDuration: 800,
                                    )
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(
                  flex: 3, // Liste alanı biraz daha büyük olsun
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Aktif İşler',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Expanded(
                          child: _buildJobListWidget(activeJobs, Colors.green.shade400),
                        ),
                        const SizedBox(height: 16),
                        Text('Bitmiş İşler',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Expanded(
                          child: _buildJobListWidget(finishedJobs, Colors.blue.shade400),
                        ),
                      ],
                    ),
                  ),
                ),
                const VerticalDivider(width: 1, thickness: 1),
                // Departman Bazlı İş Takibi
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Departman Bazlı İş Takibi',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text('Onaylanan işlerin departmanlara göre dağılımı',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            )),
                        const SizedBox(height: 16),
                        Expanded(
                          child: _buildDepartmentChart(jobProvider),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildParticle(int index) {
    final random = Random(index);
    final size = random.nextDouble() * 4 + 2;
    final left = random.nextDouble() * MediaQuery.of(context).size.width;
    final top = random.nextDouble() * MediaQuery.of(context).size.height;
    final duration = random.nextInt(10) + 10;
    
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        final progress = _particleController.value;
        final yOffset = sin(progress * 2 * pi + index) * 20;
        
        return Positioned(
          left: left,
          top: top + yOffset,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF8B5CF6).withOpacity(0.3 + random.nextDouble() * 0.4),
                  const Color(0xFFEC4899).withOpacity(0.2 + random.nextDouble() * 0.3),
                  const Color(0xFFF59E0B).withOpacity(0.1 + random.nextDouble() * 0.2),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.4),
                  blurRadius: size * 3,
                ),
                BoxShadow(
                  color: const Color(0xFFEC4899).withOpacity(0.3),
                  blurRadius: size * 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCircularSegment(int index) {
     final angle = (index * 45.0) * (pi / 180);
     final radius = 150.0 + (index * 20);
     final size = MediaQuery.of(context).size;
     
     return AnimatedBuilder(
       animation: _animationController,
       builder: (context, child) {
         final progress = _animationController.value;
         final rotationProgress = (_particleController.value + index * 0.1) % 1.0;
         
         return Positioned(
           left: size.width / 2 + cos(angle + rotationProgress * 2 * pi) * radius - 2,
           top: size.height / 2 + sin(angle + rotationProgress * 2 * pi) * radius - 2,
           child: Container(
             width: 4,
             height: 4,
             decoration: BoxDecoration(
               shape: BoxShape.circle,
               gradient: RadialGradient(
                 colors: [
                   const Color(0xFF8B5CF6).withOpacity(0.6 * progress),
                   const Color(0xFFEC4899).withOpacity(0.4 * progress),
                   const Color(0xFFF59E0B).withOpacity(0.2 * progress),
                 ],
               ),
               boxShadow: [
                 BoxShadow(
                   color: const Color(0xFF8B5CF6).withOpacity(0.7 * progress),
                   blurRadius: 12,
                 ),
                 BoxShadow(
                   color: const Color(0xFFEC4899).withOpacity(0.5 * progress),
                   blurRadius: 8,
                 ),
               ],
             ),
           ).animate().fadeIn(delay: (index * 100).ms),
         );
       },
     );
   }

   Widget _buildModernTextField({
     required TextEditingController controller,
     required String label,
     int? maxLength,
     String? Function(String?)? validator,
   }) {
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
       child: TextFormField(
         controller: controller,
         maxLength: maxLength,
         validator: validator,
         style: const TextStyle(color: Colors.white),
         decoration: InputDecoration(
           labelText: label,
           labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
           border: InputBorder.none,
           contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
           counterStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
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
                   const Color(0xFF8B5CF6), // Purple
                   const Color(0xFFEC4899), // Pink
                   const Color(0xFFF59E0B), // Amber
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

  Widget _buildDepartmentChart(JobProvider jobProvider) {
    final departmentStats = jobProvider.getDepartmentJobStats();
    
    if (departmentStats.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF8B5CF6).withOpacity(0.1),
              const Color(0xFFEC4899).withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF8B5CF6).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 48,
                color: Colors.white.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Henüz departman verisi bulunmuyor',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'İşler onaylandıkça burada görünecek',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final chartData = departmentStats.entries.map((entry) {
      return _ChartData(entry.key, entry.value.toDouble());
    }).toList();

    final totalJobs = departmentStats.values.fold(0, (sum, item) => sum + item);
    final colors = [
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      const Color(0xFF3B82F6),
      const Color(0xFFEF4444),
      const Color(0xFF8B5A2B),
      const Color(0xFF6366F1),
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF8B5CF6).withOpacity(0.1),
            const Color(0xFFEC4899).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SfCircularChart(
          enableMultiSelection: false,
          legend: Legend(
            isVisible: true,
            overflowMode: LegendItemOverflowMode.wrap,
            position: LegendPosition.bottom,
            textStyle: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
          series: <CircularSeries>[
            PieSeries<_ChartData, String>(
              dataSource: chartData,
              xValueMapper: (_ChartData data, _) => data.x,
              yValueMapper: (_ChartData data, _) => data.y,
              pointColorMapper: (_ChartData data, int index) {
                return colors[index % colors.length];
              },
              dataLabelMapper: (_ChartData data, _) {
                final double percentage = totalJobs > 0
                    ? (data.y / totalJobs * 100)
                    : 0;
                return '${data.y.toInt()}\n(${percentage.toStringAsFixed(0)}%)';
              },
              dataLabelSettings: DataLabelSettings(
                isVisible: true,
                textStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 11,
                ),
                labelPosition: ChartDataLabelPosition.outside,
              ),
              animationDuration: 1000,
              radius: '80%',
            )
          ],
        ),
      ),
    );
  }

  Widget _buildJobListWidget(List<Map<String, dynamic>> jobs, Color color) {
    if (jobs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF8B5CF6).withOpacity(0.1),
              const Color(0xFFEC4899).withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF8B5CF6).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Center(
            child: Text(
          color == Colors.green.shade400 ? 'Aktif iş bulunmuyor.' : 'Henüz bitmiş iş yok.',
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        )),
      );
    }
    
    // Bitmiş işler için çöp kutusu simgesi ekle
    final isFinishedJobs = color == Colors.blue.shade400;
    
    return ListView.builder(
      itemCount: jobs.length,
      itemExtent: 80, // Sabit yükseklik performansı artırır
      physics: const AlwaysScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final job = jobs[index];
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
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
              color: const Color(0xFF8B5CF6).withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            dense: true,
            title: Text(job['title'],
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            subtitle: job['company_name'] != null
                ? Text(job['company_name'], 
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)
                : null,
            trailing: isFinishedJobs ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  colors: [
                    Colors.red.shade400,
                    Colors.red.shade600,
                  ],
                ),
              ),
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.white, size: 18),
                onPressed: () => _showDeleteJobDialog(job),
                tooltip: 'İşi Sil',
              ),
            ) : null,
          ),
        );
      },
    );
  }
}

class _ChartData {
  _ChartData(this.x, this.y);
  final String x;
  final double y;
}

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