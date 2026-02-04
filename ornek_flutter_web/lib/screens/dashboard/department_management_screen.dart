import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_profile_model.dart';
import '../../models/department_model.dart';


// --- DEPARTMAN YÖNETİMİ BÖLÜMÜ ---
class DepartmentManagementScreen extends StatefulWidget {
  const DepartmentManagementScreen({super.key});

  @override
  _DepartmentManagementScreenState createState() => _DepartmentManagementScreenState();
}

class _DepartmentManagementScreenState extends State<DepartmentManagementScreen> {
  late Future<List<UserProfile>> _usersFuture;
  late Future<List<Department>> _departmentsFuture;
  String? _selectedDepartmentId;

  @override
  void initState() {
    super.initState();
    _reloadData();
  }

  void _reloadData() {
    setState(() {
      _usersFuture = _fetchUsersWithDepartments(_selectedDepartmentId);
      _departmentsFuture = _fetchAllDepartments();
    });
  }

  Future<List<UserProfile>> _fetchUsersWithDepartments(String? departmentId) async {
    try {
      // Debug: Onay sonrası yenileme için
      print("🔍 DEBUG: _fetchUsersWithDepartments çağrıldı, departmentId: $departmentId");
      
      // Profiles tablosundan kullanıcı detaylarını çek (departman filtreli)
      late final List<dynamic> profilesResponse;
      
      // Eğer belirli bir departman seçildiyse filtrele
      if (departmentId != null) {
        profilesResponse = await Supabase.instance.client
            .from('profiles')
            .select('id, username, avatar_url, department_id')
            .eq('department_id', departmentId);
        print("🔍 DEBUG: Departman filtreli sorgu çalıştırıldı");
      } else {
        profilesResponse = await Supabase.instance.client
            .from('profiles')
            .select('id, username, avatar_url, department_id');
        print("🔍 DEBUG: Tüm kullanıcılar sorgusu çalıştırıldı");
      }
      
      if (profilesResponse is! List) {
        debugPrint('Profiles tablosundan beklenen liste formatında veri gelmedi.');
        return [];
      }
      
      print("🔍 DEBUG: Profiles response alındı: ${profilesResponse.length} kullanıcı");

      // User_roles bilgilerini çek
      final userRolesResponse = await Supabase.instance.client
          .from('user_roles')
          .select('user_id, role_id');
      
      // Roles bilgilerini çek - Sadece gerekli alanları seçiyoruz
      final rolesResponse = await Supabase.instance.client
          .from('roles')
          .select('id, name'); // 'title' yerine 'name' kullandığımızı varsayıyorum, şemaya göre düzeltin.
      
      // Departments bilgilerini çek
      final departmentsResponse = await Supabase.instance.client
          .from('departments')
          .select('id, name, color_hex');

      // Mevcut kullanıcının email'ini al
      final currentUserEmail = Supabase.instance.client.auth.currentUser?.email ?? '';
      final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';

      // Verileri birleştir
      final List<UserProfile> userProfiles = [];
      
      for (final profile in profilesResponse) {
        final userId = profile['id'];
        final username = profile['username'] ?? 'İsimsiz Kullanıcı';
        
        // Eğer bu mevcut kullanıcı ise email'ini kullan, değilse username'i kullan
        final displayEmail = userId == currentUserId ? currentUserEmail : '$username@sistem.local';

        // Rol bilgisini bul
        String? userRole;
        final userRoleData = userRolesResponse.cast<Map<String, dynamic>>()
            .where((ur) => ur['user_id'] == userId)
            .toList();
        
        if (userRoleData.isNotEmpty) {
          final roleId = userRoleData.first['role_id'];
          final roleData = rolesResponse.cast<Map<String, dynamic>>()
              .where((r) => r['id'] == roleId)
              .toList();
          
          if (roleData.isNotEmpty) {
            userRole = roleData.first['name']; // 'title' yerine 'name' olarak güncellendi.
          }
        }

        // Departman bilgisini bul
        String? departmentName;
        String? departmentColor;
        final userDepartmentId = profile['department_id'];
        if (userDepartmentId != null) {
          final departmentData = departmentsResponse.cast<Map<String, dynamic>>()
              .where((dept) => dept['id'] == userDepartmentId)
              .toList();
          
          if (departmentData.isNotEmpty) {
            departmentName = departmentData.first['name'];
            departmentColor = departmentData.first['color_hex'];
          }
        }

        userProfiles.add(UserProfile(
          userId: userId,
          email: displayEmail,
          username: username,
          avatarUrl: profile['avatar_url'],
          role: userRole,
          departmentId: userDepartmentId,
          departmentName: departmentName,
          departmentColor: departmentColor,
        ));
      }

      debugPrint('✅ ${userProfiles.length} departman kullanıcısı başarıyla yüklendi (Profiles tablosundan)');
      return userProfiles;
      
    } catch (e) {
      debugPrint('Departman kullanıcıları çekilirken hata oluştu: $e');
      return [];
    }
  }

  Future<List<Department>> _fetchAllDepartments() async {
    final response = await Supabase.instance.client.from('departments').select();
    return (response as List).map((dept) => Department.fromJson(dept)).toList();
  }
  
  Future<void> _updateUserDepartment(String userId, String newDepartmentId) async {
      await Supabase.instance.client.rpc('assign_user_department',
          params: {'p_target_user_id': userId, 'p_new_department_id': newDepartmentId});
      _reloadData();
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
  
  @override
  Widget build(BuildContext context) {
    const Color darkNavyBg = Color(0xFF0A192F);
    const Color cardBlue = Color(0xFF172A46);
    const Color lightText = Color(0xFFE0E0E0);

    return Scaffold(
      backgroundColor: darkNavyBg,
      appBar: AppBar(
        title: const Text('Departman Yönetimi', style: TextStyle(color: lightText)),
        backgroundColor: cardBlue,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([_usersFuture, _departmentsFuture]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Veri yüklenemedi: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Veri bulunamadı.", style: TextStyle(color: Colors.white)));
          }
          
          final users = snapshot.data![0] as List<UserProfile>;
          final allDepartments = snapshot.data![1] as List<Department>;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButton<String?>(
                  value: _selectedDepartmentId,
                  hint: const Text('Tüm Departmanlar', style: TextStyle(color: Colors.white)),
                  isExpanded: true,
                  dropdownColor: const Color(0xFF172A46),
                  onChanged: (value) => setState(() {
                    _selectedDepartmentId = value;
                    _reloadData();
                  }),
                  items: [
                    const DropdownMenuItem(value: null, child: Text("Tüm Departmanlar", style: TextStyle(color: Colors.white))),
                    ...allDepartments.map((dept) => DropdownMenuItem(value: dept.id, child: Text(dept.name, style: const TextStyle(color: Colors.white)))),
                  ],
                ),
              ),
              Expanded(child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return _buildUserDepartmentCard(user, allDepartments);
                }
              ))
            ],
          );
        },
      ),
    );
  }

  Widget _buildUserDepartmentCard(UserProfile user, List<Department> allDepartments) {
      final Color mainText = const Color(0xFFE2E8F0);
      final Color secondaryText = const Color(0xFF94A3B8);
      final Color? departmentColor = user.departmentColor != null ? _hexToColor(user.departmentColor!) : null;
      final Color cardBackgroundColor = departmentColor != null
          ? Color.lerp(const Color(0xFF1E293B), departmentColor, 0.25)!
          : const Color(0xFF1E293B);

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: cardBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: departmentColor?.withOpacity(0.5) ?? Colors.transparent, width: 1)
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(user.avatarUrl ?? 'https://i.pravatar.cc/150?u=${user.userId}'),
                radius: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.username ?? 'İsimsiz Kullanıcı', style: TextStyle(color: mainText, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(user.departmentName ?? "Departman Atanmamış", style: TextStyle(color: departmentColor ?? secondaryText, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: secondaryText),
                color: const Color(0xFF2A3F5F),
                onSelected: (String newDepartmentId) {
                  _updateUserDepartment(user.userId, newDepartmentId);
                },
                itemBuilder: (BuildContext context) {
                  return allDepartments.map((Department department) {
                    return PopupMenuItem<String>(
                      value: department.id,
                      child: Text(department.name, style: const TextStyle(color: Colors.white)),
                    );
                  }).toList();
                },
              ),
            ],
          ),
        ),
      );
  }
} 