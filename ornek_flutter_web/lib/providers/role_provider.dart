import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/role_model.dart';

class RoleProvider with ChangeNotifier {
  List<Role> _roles = [];
  bool _isLoading = false;

  List<Role> get roles => _roles;
  bool get isLoading => _isLoading;

  // Hiyerarşik yapıyı döndüren getter
  List<Role> get hierarchicalRoles {
    final Map<String, Role> roleMap = {for (var role in _roles) role.id: role};
    final List<Role> rootRoles = [];

    for (var role in _roles) {
      if (role.parentId != null && roleMap.containsKey(role.parentId)) {
        final parent = roleMap[role.parentId]!;
        // Çocuğun zaten eklenip eklenmediğini kontrol et
        if (!parent.children.any((child) => child.id == role.id)) {
            parent.children.add(role);
        }
      } else {
        rootRoles.add(role);
      }
    }
    return rootRoles;
  }

  RoleProvider() {
    fetchRoles();
  }

  Future<void> fetchRoles() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await Supabase.instance.client
          .from('roles')
          .select()
          .order('name', ascending: true);

      // Her fetch işleminden önce çocuk listelerini temizle
      final fetchedRoles = (response as List)
          .map((data) => Role.fromJson(data)..children.clear())
          .toList();
      
      _roles = fetchedRoles;

      debugPrint('✅ Roller başarıyla çekildi: ${_roles.length} adet.');
    } catch (e) {
      debugPrint('❌ Roller çekilirken hata: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
  
  // Yeni rol ekleme
  Future<void> addRole({required String name, String? description, String? parentId, String? departmentId}) async {
    _isLoading = true;
    notifyListeners();
    try {
      await Supabase.instance.client.from('roles').insert({
        'name': name,
        'description': description,
        'parent_id': parentId,
        'department_id': departmentId,
      });
      await fetchRoles(); // Başarılı olursa veriyi yenile
    } catch (e) {
      debugPrint('❌ Rol eklenirken hata: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Rol güncelleme
  Future<void> updateRole({required String id, required String name, String? description}) async {
    _isLoading = true;
    notifyListeners();
    try {
      await Supabase.instance.client.from('roles').update({
        'name': name,
        'description': description,
      }).eq('id', id);
      await fetchRoles(); // Başarılı olursa veriyi yenile
    } catch (e) {
      debugPrint('❌ Rol güncellenirken hata: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Rol silme
  Future<void> deleteRole(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Önce bu rolün alt rollerini kontrol et
      final childRoles = _roles.where((role) => role.parentId == id).toList();
      if (childRoles.isNotEmpty) {
        debugPrint('⚠️ Bu rolün alt rolleri var, önce onları silmelisiniz.');
        // Hata mesajı göstermek daha iyi olabilir
        _isLoading = false;
        notifyListeners();
        return;
      }
      
      // Rolü veritabanından sil
      await Supabase.instance.client.from('roles').delete().eq('id', id);
      await fetchRoles(); // Başarılı olursa veriyi yenile
    } catch (e) {
      debugPrint('❌ Rol silinirken hata: $e');
      // Burada kullanıcıya bir hata mesajı göstermek iyi olabilir.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Bu metodlar artık RoleProvider'da değil, screen'de yönetiliyor.
  // Ancak referans olarak burada tutulabilir veya tamamen silinebilirler.
  // Şimdilik yoruma alıyorum.
  /*
  void _showLoadingDialog() {
    // Screen'de implemente edilecek
  }

  void _hideLoadingDialog() {
    // Screen'de implemente edilecek
  }
  */
} 