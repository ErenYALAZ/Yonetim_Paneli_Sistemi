// Bu dosya, Supabase kimlik doğrulama işlemlerini yönetecek. 

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_permission_model.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  // isAdmin yerine, tüm izinleri tutacak bir Map kullanıyoruz.
  Map<String, dynamic>? _permissions;
  String? _userRole;
  String? _userDepartmentId; // Giriş yapan kullanıcının departman ID'si
  List<String> _userPermissions = []; // Kullanıcının özel yetkileri
  List<String> _subordinateIds = []; // Kullanıcının altındaki kullanıcıların ID'leri

  // Dışarıdan erişim için getter'lar
  String? get userRole => _userRole;
  String? get userDepartmentId => _userDepartmentId;
  List<String> get userPermissions => _userPermissions;
  List<String> get subordinateIds => _subordinateIds;
  bool get isReady => _permissions != null;

  User? get user => _supabase.auth.currentUser;

  // Basit rol kontrolü - Manager rolünü kontrol eder
  bool isManager() {
    final role = _userRole?.toLowerCase() ?? '';
    return role == 'manager';
  }

  // Admin kontrolü
  bool isAdmin() {
    final role = _userRole?.toLowerCase() ?? '';
    return role == 'admin';
  }

  // Özel yetki kontrolü fonksiyonları
  bool canManageAnnouncements() {
    return isAdmin() || _userPermissions.contains(PermissionTypes.duyuru);
  }

  bool canManageControlPanel() {
    return isAdmin() || _userPermissions.contains(PermissionTypes.kontrolPaneli);
  }

  bool canManageSuppliers() {
    return isAdmin() || _userPermissions.contains(PermissionTypes.tedarikciPaneli);
  }

  bool canManageManufacturing() {
    return isAdmin() || _userPermissions.contains(PermissionTypes.imalat);
  }

  // Genel yetki kontrolü
  bool hasSpecialPermission(String permissionType) {
    return isAdmin() || _userPermissions.contains(permissionType);
  }

  // Yönetim paneli erişim kontrolü
  bool canAccessManagementPanel() {
    return isAdmin() || _userPermissions.contains('management_panel_access');
  }

  // Manuel olarak kullanıcı bilgilerini yenileme fonksiyonu
  Future<void> refreshUserData() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser != null) {
      await _fetchUserPermissions(currentUser);
      print("🔄 AuthService manuel olarak yenilendi");
    }
  }

  // Basit rol tabanlı yetki sistemi
  // Artık karmaşık permission sistemi kullanmıyoruz
  bool hasPermission(String key) {
    // Admin her şeyi yapabilir
    if (isAdmin()) return true;
    
    // Manager onay işlemlerini yapabilir
    if (isManager() && key == 'approve_jobs') return true;
    
    // Diğer durumlarda false
    return false;
  }
  
  AuthService() {
    _initialize();
  }

  void _initialize() {
    _supabase.auth.onAuthStateChange.listen((data) async {
      final Session? session = data.session;
      if (session != null) {
        // Kullanıcı giriş yaptı, rolünü ve izinlerini veritabanından çek.
        await _fetchUserPermissions(session.user);
      } else {
        // Kullanıcı çıkış yaptı, izinleri sıfırla.
        _permissions = null;
        _userRole = null;
        _userDepartmentId = null;
        _userPermissions = [];
        _subordinateIds = [];
      }
      // Değişikliği dinleyen widget'lara haber ver.
      notifyListeners();
    });

    // Uygulama açıldığında mevcut oturumu kontrol et.
    final currentSession = _supabase.auth.currentSession;
    if (currentSession != null) {
      _fetchUserPermissions(currentSession.user);
    }
  }

  // Basit kullanıcı bilgilerini çeken fonksiyon
  Future<void> _fetchUserPermissions(User user) async {
    try {
      // 1. Temel profil bilgilerini (rol, departman) çek.
      final profileResponse = await _supabase
          .from('profiles')
          .select('role, department_id')
          .eq('id', user.id)
          .maybeSingle();

      if (profileResponse != null) {
        _userRole = profileResponse['role'] as String?;
        _userDepartmentId = profileResponse['department_id'] as String?;
      } else {
        _userRole = null;
        _userDepartmentId = null;
      }

      // 2. Alt kullanıcı ID'lerini ayrı bir try-catch içinde çek.
      try {
        final subordinateResponse = await _supabase
            .from('profiles')
            .select('subordinate_ids')
            .eq('id', user.id)
            .single();
        if (subordinateResponse['subordinate_ids'] != null) {
          _subordinateIds = (subordinateResponse['subordinate_ids'] as List)
              .map((e) => e.toString())
              .toList();
        } else {
          _subordinateIds = [];
        }
      } catch (e) {
        print('⚠️ Alt kullanıcılar çekilemedi (sütun yoksa normal): $e');
        _subordinateIds = []; // Hata durumunda boş liste ata
      }

      // 3. Kullanıcının özel yetkilerini çek.
      try {
        final permissionsResponse = await _supabase
            .from('user_permissions')
            .select('permission_type')
            .eq('user_id', user.id);

        _userPermissions = permissionsResponse
            .map<String>((json) => json['permission_type'] as String)
            .toList();
        
        print("✅ Kullanıcı yetkileri yüklendi: $_userPermissions");
      } catch (e) {
        print('⚠️ Kullanıcı yetkileri çekilemedi (tablo henüz yoksa normal): $e');
        _userPermissions = [];
      }
      
      _permissions = {}; // Artık karmaşık permissions kullanmıyoruz
        
      print("✅ Yetki Sistemi: Rol: $_userRole, Departman ID: $_userDepartmentId, Özel Yetkiler: $_userPermissions, Alt Kullanıcılar: $_subordinateIds");

    } catch (e) {
      print('### Genel kullanıcı bilgisi çekme hatası: $e');
      _permissions = {};
      _userRole = null;
      _userDepartmentId = null;
      _userPermissions = [];
      _subordinateIds = [];
    }
    // Değişikliği dinleyen widget'lara haber ver.
    notifyListeners();
  }
}