import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ornek_flutter_web/models/user_profile_model.dart';

class UserProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<UserProfile> _users = [];
  List<UserProfile> get users => _users;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabase.from('profiles').select('*, departments(*)');
      
      _users = (response as List)
          .map((data) => UserProfile.fromMap(data))
          .toList();

    } catch (e) {
      _errorMessage = 'Kullanıcıları çekerken bir hata oluştu: $e';
      print(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> assignRoleToUser(String userId, String roleName) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _supabase
          .from('profiles')
          .update({'role': roleName})
          .eq('id', userId)
          .select(); // Güncellenen veriyi geri iste

      if (response.isEmpty) {
        _errorMessage = 'Rol atanamadı. (Kullanıcı bulunamadı veya RLS yetkisi engelliyor).';
        print('❌ $_errorMessage');
        return false;
      }
      
      print('✅ Kullanıcıya rol atandı: $userId -> $roleName');
      await fetchUsers(); // Lokal listeyi de tazeleyelim
      return true;

    } catch (e) {
      _errorMessage = 'Kullanıcıya rol atanırken bir veritabanı hatası oluştu: $e';
      print(_errorMessage);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> assignDepartmentToUser(String userId, String departmentId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _supabase
          .from('profiles')
          .update({'department_id': departmentId})
          .eq('id', userId)
          .select(); // Güncellenen veriyi geri iste

      if (response.isEmpty) {
        _errorMessage = 'Departman atanamadı. (Kullanıcı bulunamadı veya RLS yetkisi engelliyor).';
        print('❌ $_errorMessage');
        return false;
      }
      
      print('✅ Kullanıcıya departman atandı: $userId -> $departmentId');
      await fetchUsers(); // Lokal listeyi de tazeleyelim
      return true;

    } catch (e) {
      _errorMessage = 'Kullanıcıya departman atanırken bir veritabanı hatası oluştu: $e';
      print(_errorMessage);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> assignRoleAndDepartmentToUser(String userId, String roleName, String departmentId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _supabase
          .from('profiles')
          .update({
            'role': roleName,
            'department_id': departmentId
          })
          .eq('id', userId)
          .select(); // Güncellenen veriyi geri iste

      if (response.isEmpty) {
        _errorMessage = 'Rol ve departman atanamadı. (Kullanıcı bulunamadı veya RLS yetkisi engelliyor).';
        print('❌ $_errorMessage');
        return false;
      }
      
      print('✅ Kullanıcıya rol ve departman atandı: $userId -> $roleName, $departmentId');
      await fetchUsers(); // Lokal listeyi de tazeleyelim
      return true;

    } catch (e) {
      _errorMessage = 'Kullanıcıya rol ve departman atanırken bir veritabanı hatası oluştu: $e';
      print(_errorMessage);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<List<UserProfile>> fetchUsersByRole(String roleName) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('*, departments(*)')
          .eq('role', roleName);
          
      return (response as List)
          .map((data) => UserProfile.fromMap(data))
          .toList();

    } catch (e) {
      print('Role göre kullanıcıları çekerken hata: $e');
      
      // Fallback: Cache'deki tüm kullanıcılardan bu role sahip olanları filtrele
      return _users.where((user) => user.role == roleName).toList();
    }
  }
} 