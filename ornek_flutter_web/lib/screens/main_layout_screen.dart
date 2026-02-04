import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/supplier_tedarikci_provider.dart';
import '../services/auth_service.dart';
import 'auth_gate.dart';
import 'dashboard/control_panel_screen.dart';
import 'dashboard/supplier_screen.dart';
import 'profile_screen.dart';
import 'package:ornek_flutter_web/screens/announcements_screen.dart';
export 'package:ornek_flutter_web/screens/announcements_screen.dart' show AddAnnouncementDialog;
import 'package:ornek_flutter_web/providers/announcement_provider.dart';
import 'dashboard/manufacturing_screen.dart';
import 'package:ornek_flutter_web/providers/job_provider.dart';
import 'dashboard/management_screen.dart'; // Yeni ekranı import ediyoruz
import 'dashboard/approval_screen.dart'; // Yeni Onay ekranını import ediyoruz
import 'dashboard/welcome_screen.dart'; // Hoş geldiniz ekranını import et

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  static _MainLayoutScreenState? of(BuildContext context) {
    return context.findAncestorStateOfType<_MainLayoutScreenState>();
  }

  @override
  _MainLayoutScreenState createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  String? _username;
  String? _avatarUrl;

  // Sayfaları burada tanımla
  static const List<Widget> _widgetOptions = <Widget>[
    WelcomeScreen(),      // 0 - YENİ
    AnnouncementsScreen(), // 1
    ControlPanelScreen(), // 2
    SupplierScreen(), // 3
    ManufacturingScreen(), // 4
    ApprovalScreen(), // 5 - Yeni Onay Ekranı
    Center(child: Text('Sevk Ekranı')), // 6
    ManagementScreen(), // 7
    ProfileScreen(), // 8
  ];

  @override
  void initState() {
    super.initState();
    _getProfile();
    
    // Auth state değişikliklerini dinle
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final user = data.session?.user;
      
      if (event == AuthChangeEvent.signedIn && user != null) {
        print('🔐 Kullanıcı giriş yaptı: ${user.email}');
        // Yeni kullanıcı girişinde provider'ları temizle ve yeniden yükle
        if (mounted) {
          final provider = context.read<AnnouncementProvider>();
          provider.initializeForUser();
          // Cache'i bypass ederek fresh data çek
          provider.fetchAnnouncements(forceRefresh: true);
          _getProfile(); // Profil bilgilerini yenile
        }
      } else if (event == AuthChangeEvent.signedOut) {
        print('🔓 Kullanıcı çıkış yaptı');
        // Çıkış yapıldığında provider'ları temizle
        if (mounted) {
          context.read<AnnouncementProvider>().clearUserData();
        }
      }
    });
  }

  Future<void> _getProfile() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
        setState(() {
        _username = (data['username'] ?? '') as String;
        _avatarUrl = (data['avatar_url'] ?? '') as String;
        });
    } catch (e) {
      // Handle error
    }
  }

  void onItemTapped(int index) {
    // Debug: Hangi ekranın seçildiğini logla
    // print("📍 MainLayout: Ekran değişti - Index: $index (${_getAppBarTitle(index)})");
    
    setState(() {
      _selectedIndex = index;
    });
    
    // Onay ekranı seçildiğinde özel işlem
    if (index == 5) { // Index'i 5 olarak güncelle
      print("🔄 MainLayout: Onay ekranı seçildi - Veri yenileme tetikleniyor");
      // Bu notification ApprovalScreen'de dinlenebilir
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Onay ekranının yenilenmesi için bir callback
        if (mounted) {
          print("⚡ MainLayout: PostFrameCallback - Onay ekranı için tetiklendi");
        }
      });
    }
    
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final announcementProvider = Provider.of<AnnouncementProvider>(context);
    final jobProvider = Provider.of<JobProvider>(context);
    final unreadCount = announcementProvider.unreadCount;
    final myActiveJobCount = jobProvider.myActiveJobCount;
    final authService = Provider.of<AuthService>(context, listen: false); // AuthService'i al
    // print("🎨 MainLayout BİLDİRİM SAYISI GÜNCELLENDİ: Duyurular: $unreadCount, İşler: $myActiveJobCount");

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_getAppBarTitle(_selectedIndex)),
        actions: _selectedIndex == 1 ? [ // Sadece duyurular sayfasında göster
          Consumer<AuthService>(
            builder: (context, authService, child) {
              if (authService.isAdmin() || authService.canManageAnnouncements()) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF6A1B9A),
                        Color(0xFF8E24AA),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6A1B9A).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: () {
                      _showAddAnnouncementDialog();
                    },
                    tooltip: 'Duyuru Ekle',
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ] : [],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(_username ?? 'Kullanıcı'),
              accountEmail: Text(Supabase.instance.client.auth.currentUser?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                    ? NetworkImage(_avatarUrl!)
                    : null,
                child: _avatarUrl == null || _avatarUrl!.isEmpty
                ? const Icon(Icons.person, size: 50)
                    : null,
              ),
            ),
            _buildDrawerItem(
              icon: Icons.home_outlined, // Ana sayfa ikonu
              text: 'Ana Sayfa',
              index: 0, // Yeni index
            ),
            _buildDrawerItem(
              icon: Icons.campaign_outlined,
              text: 'Duyurular',
              index: 1, // Yeni index
              notificationCount: context.watch<AnnouncementProvider>().unreadCount,
            ),
            _buildDrawerItem(
              icon: Icons.dashboard_outlined,
              text: 'Kontrol Paneli',
              index: 2, // Yeni index
            ),
            _buildDrawerItem(
              icon: Icons.business,
              text: 'Tedarikçi',
              index: 3, // Yeni index
            ),
            ExpansionTile(
              leading: const Icon(Icons.precision_manufacturing_outlined, color: Colors.white70),
              title: const Text('İmalat', style: TextStyle(color: Colors.white)),
              trailing: myActiveJobCount > 0
                  ? CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.red,
                      child: Text(
                        myActiveJobCount.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    )
                  : const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
              children: <Widget>[
                _buildDrawerItem(
                  icon: Icons.factory_outlined,
                  text: 'Aktif İşler',
                  index: 4, // Yeni index
                  isSubItem: true,
                ),
                _buildDrawerItem(
                  icon: Icons.check_circle_outline,
                  text: 'Onay',
                  index: 5, // Yeni index
                  isSubItem: true,
                ),
              ],
              onExpansionChanged: (isExpanded) {
                // İmalat menüsü açıldığında otomatik olarak 'Aktif İşler' sekmesine yönlendir.
                if (isExpanded && _selectedIndex != 4 && _selectedIndex != 5) {
                  onItemTapped(4);
                }
              },
            ),
            _buildDrawerItem(
              icon: Icons.local_shipping_outlined,
              text: 'Sevk',
              index: 6, // Yeni index
            ),

            // Yönetim menüsü - sadece admin ve yetki verilmiş kullanıcılar
            Consumer<AuthService>(
              builder: (context, authService, child) {
                if (authService.canAccessManagementPanel()) {
                  return _buildDrawerItem(
                    icon: Icons.admin_panel_settings_outlined,
                    text: 'Yönetim',
                    index: 7, // Güncellenen index
                  );
                }
                return const SizedBox.shrink(); // Gizle
              },
            ),

            const Divider(),
            _buildDrawerItem(
              icon: Icons.person_outline,
              text: 'Profil',
              index: 8, // Güncellenen index
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Çıkış Yap'),
              onTap: () async {
                await Supabase.instance.client.auth.signOut();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const AuthGate()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required int index,
    int notificationCount = 0,
    Widget? trailing,
    bool isSubItem = false,
  }) {
    final isSelected = _selectedIndex == index;
    final hasNotifications = notificationCount > 0;
    
    return Padding(
      padding: EdgeInsets.only(left: isSubItem ? 32.0 : 8.0, right: 8.0, top: 4.0, bottom: 4.0),
      child: ListTile(
        leading: Icon(
          icon, 
          color: isSelected ? Theme.of(context).primaryColor : Colors.white70
        ),
        title: Row(
          children: [
            Text(
              text, 
              style: TextStyle(
                color: isSelected ? Theme.of(context).primaryColor : Colors.white
              )
            ),
            if (hasNotifications) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+$notificationCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: trailing,
        onTap: () => onItemTapped(index),
        selected: isSelected,
        selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'Ana Sayfa';
      case 1:
        return 'Duyurular';
      case 2:
        return 'Kontrol Paneli';
      case 3:
        return 'Tedarikçi';
      case 4:
        return 'Aktif İşler'; // İmalatın altındaki sayfa
      case 5:
        return 'Onay Bekleyenler'; // Yeni eklenen sayfa
      case 6:
        return 'Sevk';
      case 7:
        return 'Yönetim';
      case 8:
        return 'Profil';
      default:
        return 'ERP Sistemi';
    }
  }

  Widget _buildBody() {
    return _widgetOptions.elementAt(_selectedIndex);
  }

  void _showAddAnnouncementDialog() {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (!authService.isAdmin() && !authService.canManageAnnouncements()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Duyuru ekleme yetkiniz yok!'), backgroundColor: Colors.red),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) {
        return AddAnnouncementDialog();
      },
    );
  }
}

// Menüdeki her bir sayfa için geçici bir placeholder widget'ı
class PlaceholderWidget extends StatelessWidget {
  final String title;
  const PlaceholderWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          title,
          style: Theme.of(context).textTheme.headlineLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}