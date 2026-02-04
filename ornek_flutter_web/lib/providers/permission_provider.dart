import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_permission_model.dart';

class PermissionProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Her kullanıcı için ayrı cache
  final Map<String, List<UserPermission>> _userPermissionsCache = {};
  final Map<String, DateTime> _lastFetchTime = {};
  bool _isLoading = false;

  List<UserPermission> get userPermissions => [];
  bool get isLoading => _isLoading;
  
  // Cache süresi (5 dakika)
  static const Duration _cacheExpiry = Duration(minutes: 5);
  
  // Cache'i temizle
  void clearCache([String? userId]) {
    if (userId != null) {
      _userPermissionsCache.remove(userId);
      _lastFetchTime.remove(userId);
    } else {
      _userPermissionsCache.clear();
      _lastFetchTime.clear();
    }
    notifyListeners();
  }

  // Belirli bir kullanıcının yetkilerini getir
  Future<List<UserPermission>> fetchUserPermissions(String userId) async {
    // Cache kontrol et
    final lastFetch = _lastFetchTime[userId];
    final now = DateTime.now();
    
    if (lastFetch != null && 
        now.difference(lastFetch) < _cacheExpiry && 
        _userPermissionsCache.containsKey(userId)) {
      // Cache geçerli, mevcut veriyi döndür
      return _userPermissionsCache[userId] ?? [];
    }

    try {
      _isLoading = true;

      final response = await _supabase
          .from('user_permissions')
          .select('*')
          .eq('user_id', userId);

      final permissions = response
          .map<UserPermission>((json) => UserPermission.fromJson(json))
          .toList();

      // Cache'i güncelle
      _userPermissionsCache[userId] = permissions;
      _lastFetchTime[userId] = now;

      return permissions;
    } catch (e) {
      print('❌ Kullanıcı yetkileri getirme hatası: $e');
      _userPermissionsCache[userId] = [];
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Kullanıcının belirli bir yetkiye sahip olup olmadığını kontrol et
  bool hasPermission(String userId, String permissionType) {
    final userPermissions = _userPermissionsCache[userId] ?? [];
    return userPermissions.any((permission) => 
        permission.userId == userId && 
        permission.permissionType == permissionType);
  }

  // Kullanıcıya yetki ekle
  Future<bool> addPermission(String userId, String permissionType) async {
    try {
      // Önce zaten bu yetkiye sahip olup olmadığını kontrol et
      if (hasPermission(userId, permissionType)) {
        print('⚠️ Kullanıcı zaten bu yetkiye sahip: $permissionType');
        return false;
      }

      final newPermission = UserPermission(
        id: '', // Supabase otomatik verecek
        userId: userId,
        permissionType: permissionType,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final response = await _supabase
          .from('user_permissions')
          .insert(newPermission.toInsert())
          .select()
          .single();

      final addedPermission = UserPermission.fromJson(response);
      
      // Cache'i güncelle
      if (_userPermissionsCache.containsKey(userId)) {
        _userPermissionsCache[userId]!.add(addedPermission);
      }
      
      notifyListeners();

      print('✅ Yetki eklendi: $permissionType kullanıcıya $userId');
      return true;
    } catch (e) {
      print('❌ Yetki ekleme hatası: $e');
      return false;
    }
  }

  // Kullanıcıdan yetki kaldır
  Future<bool> removePermission(String userId, String permissionType) async {
    try {
      await _supabase
          .from('user_permissions')
          .delete()
          .eq('user_id', userId)
          .eq('permission_type', permissionType);

      // Cache'i güncelle
      if (_userPermissionsCache.containsKey(userId)) {
        _userPermissionsCache[userId]!.removeWhere((permission) => 
            permission.userId == userId && 
            permission.permissionType == permissionType);
      }
      
      notifyListeners();
      print('✅ Yetki kaldırıldı: $permissionType kullanıcıdan $userId');
      return true;
    } catch (e) {
      print('❌ Yetki kaldırma hatası: $e');
      return false;
    }
  }

  // Kullanıcıya birden fazla yetki ekle
  Future<bool> addMultiplePermissions(String userId, List<String> permissionTypes) async {
    bool allSuccess = true;
    
    for (String permissionType in permissionTypes) {
      final success = await addPermission(userId, permissionType);
      if (!success) {
        allSuccess = false;
      }
    }
    
    return allSuccess;
  }

  // Kullanıcının tüm yetkilerini kaldır
  Future<bool> removeAllPermissions(String userId) async {
    try {
      await _supabase
          .from('user_permissions')
          .delete()
          .eq('user_id', userId);

      // Cache'den kullanıcının tüm yetkilerini kaldır
      _userPermissionsCache.remove(userId);
      _lastFetchTime.remove(userId);
      notifyListeners();
      
      print('✅ Kullanıcının tüm yetkileri kaldırıldı: $userId');
      return true;
    } catch (e) {
      print('❌ Tüm yetkileri kaldırma hatası: $e');
      return false;
    }
  }

  // Kullanıcının sahip olduğu yetki türlerini liste olarak getir
  List<String> getUserPermissionTypes(String userId) {
    final userPermissions = _userPermissionsCache[userId] ?? [];
    return userPermissions
        .where((permission) => permission.userId == userId)
        .map((permission) => permission.permissionType)
        .toList();
  }

  // Tüm kullanıcıların yetkilerini getir (admin için)
  Future<Map<String, List<String>>> fetchAllUsersPermissions() async {
    try {
      final response = await _supabase
          .from('user_permissions')
          .select('*');

      final permissions = response
          .map<UserPermission>((json) => UserPermission.fromJson(json))
          .toList();

      Map<String, List<String>> userPermissionsMap = {};
      
      for (var permission in permissions) {
        if (!userPermissionsMap.containsKey(permission.userId)) {
          userPermissionsMap[permission.userId] = [];
        }
        userPermissionsMap[permission.userId]!.add(permission.permissionType);
      }

      return userPermissionsMap;
    } catch (e) {
      print('❌ Tüm kullanıcı yetkilerini getirme hatası: $e');
      return {};
    }
  }
} 