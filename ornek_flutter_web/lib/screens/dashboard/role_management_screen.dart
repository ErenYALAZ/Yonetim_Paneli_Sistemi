import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:ornek_flutter_web/models/user_profile_model.dart';
import 'package:ornek_flutter_web/providers/user_provider.dart';
import 'package:ornek_flutter_web/providers/department_provider.dart';
import 'package:ornek_flutter_web/providers/permission_provider.dart';
import 'package:ornek_flutter_web/models/user_permission_model.dart';
import 'package:provider/provider.dart';
import '../../models/role_model.dart';
import '../../providers/role_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RoleManagementScreen extends StatefulWidget {
  const RoleManagementScreen({super.key});

  @override
  State<RoleManagementScreen> createState() => _RoleManagementScreenState();
}

class _RoleManagementScreenState extends State<RoleManagementScreen> {
  OverlayEntry? _loadingOverlay;
  Map<String, bool> _expandedRoles = {}; // Her rolün açık/kapalı durumunu takip eder
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Ekran açıldığında rolleri, kullanıcıları ve departmanları çek
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isInitialized) {
        _isInitialized = true;
        Provider.of<RoleProvider>(context, listen: false).fetchRoles();
        Provider.of<UserProvider>(context, listen: false).fetchUsers();
        Provider.of<DepartmentProvider>(context, listen: false).fetchDepartments();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color darkNavyBg = Color(0xFF0A192F);
    const Color cardBlue = Color(0xFF172A46);
    const Color lightText = Color(0xFFE0E0E0);
    final roleProvider = Provider.of<RoleProvider>(context);

    return Scaffold(
      backgroundColor: darkNavyBg,
      appBar: AppBar(
        title: const Text('Rol Hiyerarşisi', style: TextStyle(color: lightText)),
        backgroundColor: cardBlue,
        actions: [
          // Bağlantı durumu göstergesi
          Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              if (userProvider.errorMessage != null && userProvider.errorMessage!.contains('SocketException')) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_off, color: Colors.orange, size: 16),
                      const SizedBox(width: 4),
                      Text('Offline', style: TextStyle(color: Colors.orange, fontSize: 12)),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          // Test butonu - geçici
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.orange),
            onPressed: () async {
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              final currentUserId = Supabase.instance.client.auth.currentUser?.id;
              
              if (currentUserId != null) {
                _showLoadingDialog();
                final success = await userProvider.assignRoleToUser(currentUserId, 'TestRole_${DateTime.now().millisecondsSinceEpoch}');
                _hideLoadingDialog();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 
                      '✅ KENDİ ROLÜNÜzü güncelleyebildik! Sorun RLS/Admin yetkisi.' : 
                      '❌ Kendi rolünüzü bile güncelleyemedik! Sorun genel veri kaydetme.'),
                    backgroundColor: success ? Colors.green : Colors.red,
                    duration: Duration(seconds: 5),
                  ),
                );
              }
            },
            tooltip: 'Veri Kaydetme Testi',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: lightText),
            onPressed: () {
              roleProvider.fetchRoles();
              Provider.of<UserProvider>(context, listen: false).fetchUsers();
              Provider.of<DepartmentProvider>(context, listen: false).fetchDepartments();
            },
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: roleProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : roleProvider.roles.isEmpty
              ? Center(
                  child: Text(
                    'Gösterilecek rol bulunamadı.',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    bool isSmallScreen = constraints.maxWidth < 600;
                    return Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          'Toplam ${roleProvider.roles.length} rol bulundu.',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _getFlatRoleList(roleProvider.hierarchicalRoles).length,
                          itemBuilder: (context, index) {
                            final flatRoles = _getFlatRoleList(roleProvider.hierarchicalRoles);
                            final roleData = flatRoles[index];
                            return Padding(
                              padding: EdgeInsets.only(left: roleData['level'] * 30.0, bottom: 8.0),
                              child: _buildRoleCard(roleData['role'], roleData['level']),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRoleDialog(context),
        label: const Text('Yeni Rol Ekle'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.purple.shade300,
      ),
    );
  }

  @override
  void dispose() {
    _hideLoadingDialog();
    super.dispose();
  }

  // Hex renk kodunu Color nesnesine çeviren fonksiyon
  Color _hexToColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.grey.shade400; // Hata durumunda varsayılan renk
    }
  }

  List<Map<String, dynamic>> _getFlatRoleList(List<Role> roles, {int level = 0}) {
    List<Map<String, dynamic>> flatList = [];
    for (var role in roles) {
      flatList.add({
        'role': role,
        'level': level,
      });
      
      // Alt roller varsa ve bu rol açıksa alt rolleri de ekle
      if (role.children.isNotEmpty && (_expandedRoles[role.id] ?? true)) {
        flatList.addAll(_getFlatRoleList(role.children, level: level + 1));
      }
    }
    return flatList;
  }

  // Rolün açık/kapalı durumunu değiştiren fonksiyon
  void _toggleRoleExpansion(String roleId) {
    setState(() {
      _expandedRoles[roleId] = !(_expandedRoles[roleId] ?? true);
    });
  }

  Widget _buildRoleCard(Role role, int level) {
    final departmentProvider = Provider.of<DepartmentProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // Direkt cache'deki kullanıcıları kullan (FutureBuilder olmadan)
    final allUsers = userProvider.users;
    final assignedUsers = allUsers.where((user) => user.role == role.name).toList();
        
        // Rol için departman rengini belirle
        Color? dominantDepartmentColor;
        String? dominantDepartmentName;
        
        // 1. ÖNCE ROL'ÜN KENDİ DEPARTMENT_ID'SİNİ KONTROL ET
        if (role.departmentId != null) {
          var department = departmentProvider.departments
              .where((dept) => dept.id == role.departmentId)
              .firstOrNull;
          if (department != null) {
            dominantDepartmentName = department.name;
            dominantDepartmentColor = _hexToColor(department.colorHex);
          }
        }
        
        // 2. Eğer rol'ün departmentId'si yoksa, rol adında departman adı var mı kontrol et
        if (dominantDepartmentColor == null) {
          String roleLower = role.name.toLowerCase();
          List<String> departmentNames = ['arge', 'imalat', 'saha', 'tasarım', 'elektrik'];
          
          for (String deptName in departmentNames) {
            if (roleLower.contains(deptName)) {
              dominantDepartmentName = deptName.substring(0, 1).toUpperCase() + deptName.substring(1);
              
              // Departman rengini DepartmentProvider'dan al
              var department = departmentProvider.departments
                  .where((dept) => dept.name.toLowerCase() == deptName)
                  .firstOrNull;
              if (department != null) {
                dominantDepartmentColor = _hexToColor(department.colorHex);
              } else {
                // Eğer departman bulunamazsa, departman adına göre sabit renk ata
                switch (deptName) {
                  case 'arge':
                    dominantDepartmentColor = _hexToColor('#FF6B6B'); // Kırmızı
                    break;
                  case 'imalat':
                    dominantDepartmentColor = _hexToColor('#4ECDC4'); // Turkuaz
                    break;
                  case 'saha':
                    dominantDepartmentColor = _hexToColor('#45B7D1'); // Mavi
                    break;
                  case 'tasarım':
                    dominantDepartmentColor = _hexToColor('#96CEB4'); // Yeşil
                    break;
                  case 'elektrik':
                    dominantDepartmentColor = _hexToColor('#FECA57'); // Sarı
                    break;
                }
              }
              break; // İlk bulunan departmanı kullan
            }
          }
        }
        
        // Rol rengini belirle (departman rengi varsa onu kullan, yoksa varsayılan)
        Color roleColor = dominantDepartmentColor ?? 
            (role.name.toLowerCase() == 'admin'
                ? Colors.red.shade300
                : role.name.toLowerCase() == 'manager'
                    ? Colors.blue.shade300
                    : Colors.purple.shade300);
                    
        // Debug bilgisi kaldırıldı (performans için)
                    
        IconData roleIcon = role.name.toLowerCase() == 'admin'
            ? Icons.admin_panel_settings
            : role.name.toLowerCase() == 'manager'
                ? Icons.manage_accounts
                : Icons.person_outline;

        // Platform kontrolü
        bool isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
        bool isSmallScreen = MediaQuery.of(context).size.width < 600;
        
        return Card(
          elevation: 4,
          margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
          color: const Color(0xFF172A46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: roleColor, width: 2.0),
          ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // Açılır kapanır ok (sadece alt roller varsa göster)
                      if (role.children.isNotEmpty) ...[
                        StatefulBuilder(
                          builder: (context, setHoverState) {
                            bool isHovered = false;
                            return MouseRegion(
                              cursor: SystemMouseCursors.click,
                              onEnter: (_) => setHoverState(() => isHovered = true),
                              onExit: (_) => setHoverState(() => isHovered = false),
                              child: GestureDetector(
                                onTap: () => _toggleRoleExpansion(role.id),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isHovered 
                                        ? Colors.white.withOpacity(0.2)
                                        : Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isHovered 
                                          ? Colors.white.withOpacity(0.4)
                                          : Colors.transparent,
                                      width: 1,
                                    ),
                                  ),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: Icon(
                                      (_expandedRoles[role.id] ?? true) 
                                          ? Icons.keyboard_arrow_down 
                                          : Icons.keyboard_arrow_right,
                                      key: ValueKey((_expandedRoles[role.id] ?? true)),
                                      color: isHovered ? Colors.white : Colors.white70,
                                      size: isHovered ? 22 : 20,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                      ] else ...[
                        // Alt rol yoksa boş alan bırak (hizalama için)
                        const SizedBox(width: 36),
                      ],
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
                          border: Border.all(color: roleColor, width: 1),
                        ),
                        child: Icon(roleIcon, color: roleColor, size: isSmallScreen ? 20 : 24),
                      ),
                      SizedBox(width: isSmallScreen ? 12 : 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              role.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: isSmallScreen ? 16 : 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (dominantDepartmentName != null) ...[
                                  if (dominantDepartmentColor != null) ...[
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: dominantDepartmentColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Text(
                                    dominantDepartmentName!,
                                    style: TextStyle(
                                      color: dominantDepartmentColor ?? Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ] else ...[
                                  Text(
                                    'Departman atanmamış',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                                if (role.children.isNotEmpty) ...[
                                  const SizedBox(width: 12),
                                  Text(
                                    '• ${role.children.length} alt rol',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildRoleActionButtons(context, role),
              ],
            ),
            const Divider(color: Colors.white24, height: 24),
            _buildAssignedUsers(context, role),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignedUsers(BuildContext context, Role role) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Direkt cache'deki kullanıcıları kullan
    final allUsers = userProvider.users;
    final assignedUsers = allUsers.where((user) => user.role == role.name).toList();
        if (assignedUsers.isEmpty) {
          return const Text('Bu role atanmış kullanıcı yok.', style: TextStyle(color: Colors.white54));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Atanmış Kullanıcılar:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: assignedUsers.map((user) {
                final userDepartmentColor = user.departmentColor != null 
                    ? _hexToColor(user.departmentColor!) 
                    : null;
                
                // Her kullanıcı için ayrı GlobalKey oluştur
                final permissionWidgetKey = GlobalKey<_UserPermissionsWidgetState>();
                
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: userDepartmentColor?.withOpacity(0.6) ?? Colors.white24,
                      width: 1.5,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      // Kullanıcı kartına tıklandığında görev bilgilerini toggle et
                      permissionWidgetKey.currentState?.toggleFromParent();
                    },
                    child: Chip(
                      avatar: CircleAvatar(
                        backgroundImage: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                            ? NetworkImage(user.avatarUrl!)
                            : null,
                        child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                            ? const Icon(Icons.person, size: 18)
                            : null,
                      ),
                      label: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.username ?? 'Bilinmeyen Kullanıcı',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                          ),
                          if (user.departmentName != null) ...[
                            const SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (userDepartmentColor != null) ...[
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: userDepartmentColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Flexible(
                                  child: Text(
                                    user.departmentName!,
                                    style: TextStyle(
                                      color: userDepartmentColor ?? Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          // Kullanıcının yetkilerini göster
                          _UserPermissionsWidget(
                            key: permissionWidgetKey,
                            userId: user.userId,
                          ),
                        ],
                      ),
                      onDeleted: () => _showRemoveUserConfirmation(context, user, role),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      backgroundColor: userDepartmentColor != null 
                          ? userDepartmentColor.withOpacity(0.15)
                          : Colors.blueGrey.shade700,
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
  }

  void _showAssignUserDialog(BuildContext context, Role role) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final departmentProvider = Provider.of<DepartmentProvider>(context, listen: false);
    String searchQuery = '';
    String? selectedDepartmentId;
    List<UserProfile> selectedUsers = [];
    Color dialogBackgroundColor = const Color(0xFF172A46);
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Seçili departmana göre arka plan rengini belirle
            if (selectedDepartmentId != null) {
              final selectedDept = departmentProvider.departments
                  .where((dept) => dept.id == selectedDepartmentId)
                  .firstOrNull;
              if (selectedDept != null) {
                Color deptColor = _hexToColor(selectedDept.colorHex);
                dialogBackgroundColor = Color.lerp(const Color(0xFF172A46), deptColor, 0.15) ?? const Color(0xFF172A46);
              }
            } else {
              dialogBackgroundColor = const Color(0xFF172A46);
            }

            final allUsers = userProvider.users;
            
            // Kullanıcıların mevcut rol sayılarını hesapla
            Map<String, int> userRoleCounts = {};
            for (var user in allUsers) {
              if (user.role != null && user.role != 'Default') {
                userRoleCounts[user.userId] = (userRoleCounts[user.userId] ?? 0) + 1;
              }
            }
            
            final filteredUsers = allUsers
                .where((user) =>
                    (user.username?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
                    (user.email?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false))
                .where((user) => user.role != role.name) // Zaten bu rolde olanları gösterme
                .where((user) => (userRoleCounts[user.userId] ?? 0) < 3) // Maksimum 3 rol sınırı
                .toList();

            return AlertDialog(
              backgroundColor: dialogBackgroundColor,
              title: Text('\'${role.name}\' Rolüne Kullanıcı Ata', style: const TextStyle(color: Colors.white)),
              content: SizedBox(
                width: 450,
                height: 600,
                child: Column(
                  children: [
                    // Arama alanı
                    TextField(
                      onChanged: (value) {
                        setDialogState(() {
                          searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Kullanıcı Ara (İsim veya Email)',
                        labelStyle: TextStyle(color: Colors.white70),
                        prefixIcon: Icon(Icons.search, color: Colors.white70),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.teal)),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    
                    // Departman seçimi
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Departman Ata (İsteğe Bağlı)',
                            style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          DropdownButton<String?>(
                            value: selectedDepartmentId,
                            hint: const Text('Departman seç', style: TextStyle(color: Colors.white54)),
                            isExpanded: true,
                            dropdownColor: const Color(0xFF2A3F5F),
                            style: const TextStyle(color: Colors.white),
                            underline: Container(),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Departman seçilmedi', style: TextStyle(color: Colors.white54)),
                              ),
                              ...departmentProvider.departments.map((dept) {
                                return DropdownMenuItem<String?>(
                                  value: dept.id,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: _hexToColor(dept.colorHex),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(dept.name, style: const TextStyle(color: Colors.white)),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                            onChanged: (value) {
                              setDialogState(() {
                                selectedDepartmentId = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Kullanıcı listesi
                    Expanded(
                      child: filteredUsers.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.info_outline, color: Colors.white54, size: 48),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Uygun kullanıcı bulunamadı.',
                                    style: TextStyle(color: Colors.white70, fontSize: 16),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tüm kullanıcılar bu role sahip olabilir\nyada maksimum 3 rol limitine ulaşmış olabilir.',
                                    style: TextStyle(color: Colors.white54, fontSize: 14),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredUsers.length,
                              itemBuilder: (context, index) {
                                final user = filteredUsers[index];
                                final userDepartmentColor = user.departmentColor != null 
                                    ? _hexToColor(user.departmentColor!) 
                                    : null;
                                
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: userDepartmentColor != null 
                                        ? userDepartmentColor.withOpacity(0.1)
                                        : Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: userDepartmentColor?.withOpacity(0.3) ?? Colors.white24,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    selected: selectedUsers.any((u) => u.userId == user.userId),
                                    selectedTileColor: Colors.blue.withOpacity(0.2),
                                    leading: CircleAvatar(
                                      backgroundImage: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                                          ? NetworkImage(user.avatarUrl!)
                                          : null,
                                      child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                                          ? const Icon(Icons.person)
                                          : null,
                                    ),
                                    title: Text(
                                      user.username ?? 'İsimsiz',
                                      style: TextStyle(
                                        color: selectedUsers.any((u) => u.userId == user.userId) ? Colors.blue.shade100 : Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(user.email ?? 'Email yok', style: const TextStyle(color: Colors.white70)),
                                        if (user.departmentName != null) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              if (userDepartmentColor != null) ...[
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    color: userDepartmentColor,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                              ],
                                              Text(
                                                user.departmentName!,
                                                style: TextStyle(
                                                  color: userDepartmentColor ?? Colors.white54,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                user.role ?? 'Rol Yok',
                                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: (userRoleCounts[user.userId] ?? 0) >= 2 
                                                    ? Colors.orange.withOpacity(0.3)
                                                    : Colors.green.withOpacity(0.3),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '${userRoleCounts[user.userId] ?? 0}/3 rol',
                                                style: TextStyle(
                                                  color: (userRoleCounts[user.userId] ?? 0) >= 2 
                                                      ? Colors.orange.shade200
                                                      : Colors.green.shade200,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (selectedUsers.any((u) => u.userId == user.userId)) ...[
                                          const SizedBox(width: 8),
                                          Icon(Icons.check_circle, color: Colors.blue.shade300, size: 20),
                                        ],
                                      ],
                                    ),
                                    onTap: () {
                                      setDialogState(() {
                                        if (selectedUsers.any((u) => u.userId == user.userId)) {
                                          selectedUsers.removeWhere((u) => u.userId == user.userId);
                                        } else {
                                          selectedUsers.add(user);
                                        }
                                      });
                                    },
                                  ),
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
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: selectedUsers.isEmpty ? null : () async {
                    // Async işlem öncesi context'e bağlı nesneleri yakala
                    final navigator = Navigator.of(dialogContext);
                    final messenger = ScaffoldMessenger.of(context);

                    navigator.pop(); // Dialogu kapat
                    _showLoadingDialog();
                    
                    int successCount = 0;
                    int totalCount = selectedUsers.length;
                    List<String> failedUsers = [];
                    
                    for (UserProfile user in selectedUsers) {
                      bool success;
                      if (selectedDepartmentId != null) {
                        // Hem rol hem departman ata
                        success = await userProvider.assignRoleAndDepartmentToUser(
                          user.userId, role.name, selectedDepartmentId!);
                      } else {
                        // Sadece rol ata
                        success = await userProvider.assignRoleToUser(user.userId, role.name);
                      }
                      
                      if (success) {
                        successCount++;
                      } else {
                        failedUsers.add(user.username ?? user.email ?? 'Bilinmeyen');
                      }
                    }
                    
                    _hideLoadingDialog();

                    if (!mounted) return;

                    String message;
                    if (successCount == totalCount) {
                      message = '$successCount kullanıcıya ${role.name} rolü başarıyla atandı.';
                      if (selectedDepartmentId != null) {
                        final selectedDept = departmentProvider.departments
                            .firstWhere((dept) => dept.id == selectedDepartmentId);
                        message += ' Departman: ${selectedDept.name}';
                      }
                      
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(message), 
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    } else if (successCount > 0) {
                      message = '$successCount/$totalCount kullanıcıya rol atandı.';
                      if (failedUsers.isNotEmpty) {
                        message += '\nBaşarısız: ${failedUsers.join(", ")}';
                      }
                      
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(message), 
                          backgroundColor: Colors.orange,
                          duration: Duration(seconds: 4),
                        ),
                      );
                    } else {
                      message = 'Hiçbir kullanıcıya rol atanamadı.';
                      if (failedUsers.isNotEmpty) {
                        message += '\nBaşarısız: ${failedUsers.join(", ")}';
                      }
                      
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(message), 
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 4),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedUsers.isNotEmpty ? Colors.blue : Colors.grey,
                  ),
                  child: Text(
                    selectedUsers.isNotEmpty 
                        ? 'Kaydet (${selectedUsers.length} kullanıcı)' 
                        : 'Kullanıcı Seç',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  void _showRemoveUserConfirmation(BuildContext context, UserProfile user, Role role) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Async işlem öncesi context'e bağlı nesneleri yakala
        final navigator = Navigator.of(dialogContext);
        final messenger = ScaffoldMessenger.of(context);
        final userProvider = Provider.of<UserProvider>(context, listen: false);

        return AlertDialog(
          backgroundColor: const Color(0xFF172A46),
          title: Text('Kullanıcıyı Rolden Kaldır', style: TextStyle(color: Colors.white)),
          content: Text('${user.username} kullanıcısını ${role.name} rolünden kaldırmak istediğinize emin misiniz? Bu işlem kullanıcının rolünü "Default" olarak ayarlayacaktır.', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () async {
                navigator.pop();
                _showLoadingDialog();
                final success = await userProvider.assignRoleToUser(user.userId, 'Default');
                _hideLoadingDialog();

                if (!mounted) return;

                if (success) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('${user.username} kullanıcısı rolden kaldırıldı.'), backgroundColor: Colors.green),
                  );
                   // UI Consumer sayesinde otomatik güncellenecek
                } else {
                  messenger.showSnackBar(
                    SnackBar(content: Text('İşlem başarısız oldu.'), backgroundColor: Colors.red),
                  );
                }
              },
              child: Text('Kaldır', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }


  // -- Mevcut Dialog Fonksiyonları --
  // (Değişiklik yok, olduğu gibi kalıyorlar)

  void _showAddRoleDialog(BuildContext context, {Role? parentRole}) {
    final roleProvider = Provider.of<RoleProvider>(context, listen: false);
    final departmentProvider = Provider.of<DepartmentProvider>(context, listen: false);
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    String? selectedDepartmentId;
    Color dialogBackgroundColor = const Color(0xFF172A46);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Seçili departmana göre arka plan rengini belirle
            if (selectedDepartmentId != null) {
              final selectedDept = departmentProvider.departments
                  .where((dept) => dept.id == selectedDepartmentId)
                  .firstOrNull;
              if (selectedDept != null) {
                Color deptColor = _hexToColor(selectedDept.colorHex);
                dialogBackgroundColor = Color.lerp(const Color(0xFF172A46), deptColor, 0.15) ?? const Color(0xFF172A46);
              }
            } else {
              dialogBackgroundColor = const Color(0xFF172A46);
            }

            return AlertDialog(
              backgroundColor: dialogBackgroundColor,
              title: Text(
                parentRole == null ? 'Yeni Kök Rol Ekle' : '\'${parentRole.name}\' Rolüne Alt Rol Ekle', 
                style: const TextStyle(color: Colors.white)
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Rol Adı', 
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Açıklama', 
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Departman seçimi
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Varsayılan Departman (İsteğe Bağlı)',
                            style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          DropdownButton<String?>(
                            value: selectedDepartmentId,
                            hint: const Text('Departman seç', style: TextStyle(color: Colors.white54)),
                            isExpanded: true,
                            dropdownColor: const Color(0xFF2A3F5F),
                            style: const TextStyle(color: Colors.white),
                            underline: Container(),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Departman seçilmedi', style: TextStyle(color: Colors.white54)),
                              ),
                              ...departmentProvider.departments.map((dept) {
                                return DropdownMenuItem<String?>(
                                  value: dept.id,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: _hexToColor(dept.colorHex),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(dept.name, style: const TextStyle(color: Colors.white)),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                            onChanged: (value) {
                              setDialogState(() {
                                selectedDepartmentId = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isNotEmpty) {
                      final navigator = Navigator.of(dialogContext);
                      navigator.pop();
                      _showLoadingDialog();
                      
                      await roleProvider.addRole(
                        name: nameController.text,
                        description: descriptionController.text,
                        parentId: parentRole?.id,
                        departmentId: selectedDepartmentId,
                      );
                      
                      _hideLoadingDialog();
                      
                      // Başarı mesajı
                      if (mounted) {
                        String message = '${nameController.text} rolü oluşturuldu.';
                        if (selectedDepartmentId != null) {
                          final selectedDept = departmentProvider.departments
                              .firstWhere((dept) => dept.id == selectedDepartmentId);
                          message += ' Varsayılan departman: ${selectedDept.name}';
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(message), backgroundColor: Colors.green),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade400,
                  ),
                  child: const Text('Ekle', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddChildRoleDialog(BuildContext context, Role parentRole) {
    _showAddRoleDialog(context, parentRole: parentRole);
  }

  void _showEditRoleDialog(BuildContext context, Role role) {
    final roleProvider = Provider.of<RoleProvider>(context, listen: false);
    final nameController = TextEditingController(text: role.name);
    final descriptionController = TextEditingController(text: role.description);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Async işlem öncesi context'e bağlı nesneleri yakala
        final navigator = Navigator.of(dialogContext);

        return AlertDialog(
          backgroundColor: const Color(0xFF172A46),
          title: const Text('Rolü Düzenle', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Rol Adı', labelStyle: TextStyle(color: Colors.white70)),
              ),
              TextField(
                controller: descriptionController,
                style: TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Açıklama', labelStyle: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  navigator.pop();
                  _showLoadingDialog();
                  await roleProvider.updateRole(
                    id: role.id,
                    name: nameController.text,
                    description: descriptionController.text,
                  );
                  _hideLoadingDialog();
                }
              },
              child: const Text('Güncelle'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, Role role) {
    final roleProvider = Provider.of<RoleProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Async işlem öncesi context'e bağlı nesneleri yakala
        final navigator = Navigator.of(dialogContext);
        
        return AlertDialog(
          backgroundColor: const Color(0xFF172A46),
          title: const Text('Rolü Sil', style: TextStyle(color: Colors.white)),
          content: Text('\'${role.name}\' rolünü ve tüm alt rollerini silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                navigator.pop();
                _showLoadingDialog();
                await roleProvider.deleteRole(role.id);
                _hideLoadingDialog();
              },
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );
  }

  void _showTaskAssignmentDialog(BuildContext context, Role role) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF172A46),
              title: Text(
                '${role.name} - Görev Yetkisi Ata',
                style: const TextStyle(color: Colors.white),
              ),
              content: Container(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bu role sahip kullanıcılara hangi özel yetkiler verilsin?',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    _buildPermissionOption(
                      context,
                      role,
                      PermissionTypes.duyuru,
                      PermissionTypes.permissionNames[PermissionTypes.duyuru]!,
                      PermissionTypes.permissionDescriptions[PermissionTypes.duyuru]!,
                      Icons.campaign,
                      Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    _buildPermissionOption(
                      context,
                      role,
                      PermissionTypes.kontrolPaneli,
                      PermissionTypes.permissionNames[PermissionTypes.kontrolPaneli]!,
                      PermissionTypes.permissionDescriptions[PermissionTypes.kontrolPaneli]!,
                      Icons.dashboard,
                      Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _buildPermissionOption(
                      context,
                      role,
                      PermissionTypes.tedarikciPaneli,
                      PermissionTypes.permissionNames[PermissionTypes.tedarikciPaneli]!,
                      PermissionTypes.permissionDescriptions[PermissionTypes.tedarikciPaneli]!,
                      Icons.business,
                      Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _buildPermissionOption(
                      context,
                      role,
                      PermissionTypes.imalat,
                      PermissionTypes.permissionNames[PermissionTypes.imalat]!,
                      PermissionTypes.permissionDescriptions[PermissionTypes.imalat]!,
                      Icons.precision_manufacturing,
                      Colors.purple,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Tamam'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPermissionOption(
    BuildContext context,
    Role role,
    String permissionType,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A192F).withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            onPressed: () => _assignPermissionToRoleUsers(context, role, permissionType, title),
            child: const Text('Ata', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Future<void> _assignPermissionToRoleUsers(
    BuildContext context,
    Role role,
    String permissionType,
    String permissionTitle,
  ) async {
    try {
      _showLoadingDialog();
      
      // Bu role sahip tüm kullanıcıları bul
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final permissionProvider = Provider.of<PermissionProvider>(context, listen: false);
      
      await userProvider.fetchUsers();
      final allUsers = userProvider.users;
      
      // Bu role sahip kullanıcıları filtrele (role adını kullanarak)
      final roleUsers = allUsers.where((user) {
        return user.role == role.name;
      }).toList();
      
      if (roleUsers.isEmpty) {
        _hideLoadingDialog();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${role.name} rolüne atanmış kullanıcı bulunamadı'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      // Her kullanıcıya yetkiyi ekle
      int successCount = 0;
      for (final user in roleUsers) {
        final success = await permissionProvider.addPermission(user.userId, permissionType);
        if (success) successCount++;
      }
      
      _hideLoadingDialog();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${role.name} rolündeki $successCount kullanıcıya "$permissionTitle" yetkisi verildi',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
      
    } catch (e) {
      _hideLoadingDialog();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yetki atama hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLoadingDialog() {
    if (_loadingOverlay != null) return;
    _loadingOverlay = OverlayEntry(
      builder: (context) => Container(
        color: Colors.black.withOpacity(0.5),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
    Overlay.of(context).insert(_loadingOverlay!);
  }

  void _hideLoadingDialog() {
    _loadingOverlay?.remove();
    _loadingOverlay = null;
  }

  void _showPermissionRemovalDialog(BuildContext context, Role role) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF172A46),
              title: Text(
                '${role.name} - Yetki Kaldır',
                style: const TextStyle(color: Colors.white),
              ),
              content: Container(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bu role sahip kullanıcılardan hangi yetkileri kaldırmak istiyorsunuz?',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    _buildPermissionRemovalOption(
                      context,
                      PermissionTypes.duyuru,
                      PermissionTypes.permissionNames[PermissionTypes.duyuru]!,
                      PermissionTypes.permissionDescriptions[PermissionTypes.duyuru]!,
                      Icons.campaign,
                      Colors.orange,
                      role,
                    ),
                    const SizedBox(height: 12),
                    _buildPermissionRemovalOption(
                      context,
                      PermissionTypes.kontrolPaneli,
                      PermissionTypes.permissionNames[PermissionTypes.kontrolPaneli]!,
                      PermissionTypes.permissionDescriptions[PermissionTypes.kontrolPaneli]!,
                      Icons.dashboard,
                      Colors.blue,
                      role,
                    ),
                    const SizedBox(height: 12),
                    _buildPermissionRemovalOption(
                      context,
                      PermissionTypes.tedarikciPaneli,
                      PermissionTypes.permissionNames[PermissionTypes.tedarikciPaneli]!,
                      PermissionTypes.permissionDescriptions[PermissionTypes.tedarikciPaneli]!,
                      Icons.business,
                      Colors.green,
                      role,
                    ),
                    const SizedBox(height: 12),
                    _buildPermissionRemovalOption(
                      context,
                      PermissionTypes.imalat,
                      PermissionTypes.permissionNames[PermissionTypes.imalat]!,
                      PermissionTypes.permissionDescriptions[PermissionTypes.imalat]!,
                      Icons.precision_manufacturing,
                      Colors.purple,
                      role,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Tamam'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPermissionRemovalOption(
    BuildContext context,
    String permissionType,
    String title,
    String description,
    IconData icon,
    Color color,
    Role role,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A192F).withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            onPressed: () => _removePermissionFromRoleUsers(context, role, permissionType, title),
            child: const Text('Kaldır', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Future<void> _removePermissionFromRoleUsers(
    BuildContext context,
    Role role,
    String permissionType,
    String permissionTitle,
  ) async {
    try {
      _showLoadingDialog();
      
      // Bu role sahip tüm kullanıcıları bul
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final permissionProvider = Provider.of<PermissionProvider>(context, listen: false);
      
      await userProvider.fetchUsers();
      final allUsers = userProvider.users;
      
      // Bu role sahip kullanıcıları filtrele
      final roleUsers = allUsers.where((user) {
        return user.role == role.name;
      }).toList();
      
      if (roleUsers.isEmpty) {
        _hideLoadingDialog();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${role.name} rolüne atanmış kullanıcı bulunamadı'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      // Her kullanıcıdan yetkiyi kaldır
      int successCount = 0;
      for (final user in roleUsers) {
        final success = await permissionProvider.removePermission(user.userId, permissionType);
        if (success) successCount++;
      }
      
      _hideLoadingDialog();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${role.name} rolündeki $successCount kullanıcıdan "$permissionTitle" yetkisi kaldırıldı',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      // Kullanıcı kartlarını yenile
      setState(() {});
      
    } catch (e) {
      _hideLoadingDialog();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yetki kaldırma hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Kullanıcının yetkilerini getir
  Future<List<String>> _getUserPermissions(String userId) async {
    try {
      final permissionProvider = Provider.of<PermissionProvider>(context, listen: false);
      await permissionProvider.fetchUserPermissions(userId);
      return permissionProvider.getUserPermissionTypes(userId);
    } catch (e) {
      print('❌ Kullanıcı yetkileri getirme hatası: $e');
      return [];
    }
  }

  // Rol aksiyon butonlarını platform bazında responsive olarak oluştur
  Widget _buildRoleActionButtons(BuildContext context, Role role) {
    // Platform kontrolü
    bool isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    
    // Mobil cihazlar için ekran genişliği kontrolü
    bool isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    List<Widget> buttons = [
      ElevatedButton.icon(
        icon: const Icon(Icons.person_add_alt_1, size: 16),
        label: Text(isSmallScreen ? 'Ata' : 'Kullanıcı Ata'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal.shade400,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 8 : 12, 
            vertical: 8
          ),
        ),
        onPressed: () => _showAssignUserDialog(context, role),
      ),
      ElevatedButton.icon(
        icon: const Icon(Icons.add, size: 16),
        label: Text(isSmallScreen ? 'Alt' : 'Alt Rol'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade400,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 8 : 12, 
            vertical: 8
          ),
        ),
        onPressed: () => _showAddChildRoleDialog(context, role),
      ),
      ElevatedButton.icon(
        icon: const Icon(Icons.assignment, size: 16),
        label: Text(isSmallScreen ? 'Görev' : 'Görev'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple.shade400,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 8 : 12, 
            vertical: 8
          ),
        ),
        onPressed: () => _showTaskAssignmentDialog(context, role),
      ),
      ElevatedButton.icon(
        icon: const Icon(Icons.remove_circle, size: 16),
        label: Text(isSmallScreen ? 'Sil' : 'Yetki Sil'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade400,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 8 : 12, 
            vertical: 8
          ),
        ),
        onPressed: () => _showPermissionRemovalDialog(context, role),
      ),
    ];
    
    List<Widget> iconButtons = [
      IconButton(
        icon: const Icon(Icons.edit, color: Colors.blue),
        onPressed: () => _showEditRoleDialog(context, role),
        tooltip: 'Rolü Düzenle',
      ),
      IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () => _showDeleteConfirmation(context, role),
        tooltip: 'Rolü Sil',
      ),
    ];
    
    if (isMobile || isSmallScreen) {
      // Mobil cihazlar için wrap layout
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 4.0,
            runSpacing: 4.0,
            children: buttons,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: iconButtons,
          ),
        ],
      );
    } else {
      // Masaüstü için row layout
      return Row(
        children: [
          ...buttons.expand((button) => [button, const SizedBox(width: 8)]).toList()..removeLast(),
          const SizedBox(width: 8),
          ...iconButtons,
        ],
      );
    }
  }
}

// Ayrı widget olarak kullanıcı yetkilerini göster
class _UserPermissionsWidget extends StatefulWidget {
  final String userId;
  final VoidCallback? onToggle;

  const _UserPermissionsWidget({required this.userId, this.onToggle, super.key});

  @override
  State<_UserPermissionsWidget> createState() => _UserPermissionsWidgetState();
}

class _UserPermissionsWidgetState extends State<_UserPermissionsWidget> {
  List<String> _permissions = [];
  bool _isLoading = true;
  bool _isExpanded = false;
  static final Map<String, List<String>> _permissionCache = {};

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    if (!mounted) return;
    
    // Cache kontrolü
    if (_permissionCache.containsKey(widget.userId)) {
      setState(() {
        _permissions = _permissionCache[widget.userId]!;
        _isLoading = false;
      });
      return;
    }
    
    try {
      final permissionProvider = Provider.of<PermissionProvider>(context, listen: false);
      final permissions = permissionProvider.getUserPermissionTypes(widget.userId);
      
      if (mounted) {
        _permissionCache[widget.userId] = permissions;
        setState(() {
          _permissions = permissions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _permissions = [];
          _isLoading = false;
        });
      }
    }
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    // Eğer onToggle callback'i varsa çağır
    widget.onToggle?.call();
  }

  // Dışarıdan toggle edilebilmesi için public method
  void toggleFromParent() {
    _toggleExpansion();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink(); // Loading durumunda hiçbir şey gösterme
    }

    if (_permissions.isEmpty) {
      return const SizedBox.shrink(); // Yetki yoksa hiçbir şey gösterme
    }

    final permissionNames = _permissions.map((p) => 
      PermissionTypes.permissionNames[p] ?? p
    ).join(', ');
    
    return GestureDetector(
      onTap: _toggleExpansion,
      child: Container(
        margin: const EdgeInsets.only(top: 2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: _isExpanded ? 8 : 0,
            vertical: _isExpanded ? 4 : 0,
          ),
          decoration: _isExpanded ? BoxDecoration(
            color: Colors.amber.shade300.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Colors.amber.shade300.withOpacity(0.5),
              width: 1,
            ),
          ) : null,
          child: Text(
            _isExpanded 
                ? '🔑 Görevler: $permissionNames'
                : '🔑 $permissionNames',
            style: TextStyle(
              color: Colors.amber.shade300,
              fontSize: _isExpanded ? 11 : 10,
              fontWeight: FontWeight.w500,
            ),
            maxLines: _isExpanded ? 3 : 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}