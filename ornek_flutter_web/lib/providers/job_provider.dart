import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class JobProvider with ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;
  List<Map<String, dynamic>> _activeJobs = [];
  List<Map<String, dynamic>> _pendingJobs = [];
  List<Map<String, dynamic>> _completedJobs = [];
  int _myActiveJobCount = 0;
  bool _isLoading = false;
  String? _lastCheckedUserId;
  
  // Cache için
  DateTime? _lastFetchTime;
  static const Duration _cacheTimeout = Duration(minutes: 2);
  Map<String, String> _departmentCache = {};

  List<Map<String, dynamic>> get activeJobs => _activeJobs;
  List<Map<String, dynamic>> get pendingJobs => _pendingJobs;
  List<Map<String, dynamic>> get completedJobs => _completedJobs;
  int get myActiveJobCount => _myActiveJobCount;
  bool get isLoading => _isLoading;

  JobProvider() {
    print("✅ JobProvider oluşturuldu.");
    checkForUserChangeAndFetch();
  }

  void checkForUserChangeAndFetch() {
    final currentUserId = _client.auth.currentUser?.id;
    print("🔄 checkForUserChangeAndFetch tetiklendi. Mevcut Kullanıcı: $currentUserId, Son Kontrol: $_lastCheckedUserId");
    if (currentUserId != _lastCheckedUserId) {
      print("❗️ Kullanıcı değişti! Veriler yeniden çekiliyor...");
      _lastCheckedUserId = currentUserId;
      fetchAllJobs();
    } else {
      print("ℹ️ Kullanıcı aynı, veri çekmeye gerek yok.");
    }
  }

  Future<void> fetchAllJobs({String? departmentId, bool forceRefresh = false}) async {
    if (_isLoading) return;
    
    // Cache kontrolü
    if (!forceRefresh && _lastFetchTime != null) {
      final timeDiff = DateTime.now().difference(_lastFetchTime!);
      if (timeDiff < _cacheTimeout) {
        print("📋 Cache'den veri kullanılıyor (${timeDiff.inSeconds}s önce çekildi)");
        return;
      }
    }
    
    _isLoading = true;
    notifyListeners();

    try {
      print("⏳ Tüm işler çekiliyor... Filtre: ${departmentId ?? 'Yok'}");
      
      // Departman cache'ini güncelle
      await _updateDepartmentCache();

      // Tüm işleri çek (JOIN olmadan)
      final allJobsResponse = await _client
          .from('jobs')
          .select('*')
          .order('created_at', ascending: false);
      
      final allJobs = List<Map<String, dynamic>>.from(allJobsResponse ?? []);
      
      // İşleri durumlarına göre ayır
      _activeJobs = allJobs.where((job) => job['status'] == 'Aktif').toList();
      _completedJobs = allJobs.where((job) => job['status'] == 'Bitmiş').toList();
      
      // Departman adlarını cache'den ekle
      for (var job in [..._activeJobs, ..._completedJobs]) {
        if (job['department_id'] != null) {
          final deptId = job['department_id'].toString();
          if (_departmentCache.containsKey(deptId)) {
            job['dept_name'] = _departmentCache[deptId];
          } else {
            job['dept_name'] = 'Bilinmeyen Departman';
          }
        } else {
          job['dept_name'] = 'Departman Atanmamış';
        }
      }
      
      print("✅ Aktif işler: ${_activeJobs.length}, Bitmiş işler: ${_completedJobs.length}");

      // Onay bekleyen işler - RPC kullan
      final pendingResponse = await _client.rpc('get_pending_approval_jobs');
      _pendingJobs = List<Map<String, dynamic>>.from(pendingResponse ?? []);
      
      // Onay bekleyen işlere de departman adlarını ekle
      for (var job in _pendingJobs) {
        if (job['department_id'] != null) {
          final deptId = job['department_id'].toString();
          if (_departmentCache.containsKey(deptId)) {
            job['dept_name'] = _departmentCache[deptId];
          } else {
            job['dept_name'] = 'Bilinmeyen Departman';
          }
        } else {
          job['dept_name'] = 'Departman Atanmamış';
        }
      }
      
      print("✅ Onay bekleyen işler: ${_pendingJobs.length}");

      _calculateMyJobCount();
      _lastFetchTime = DateTime.now();
    } catch (e) {
      print('❌ İşler yüklenirken hata: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> _updateDepartmentCache() async {
    try {
      final deptResponse = await _client
          .from('departments')
          .select('id, name');
      
      _departmentCache.clear();
      for (var dept in deptResponse) {
        final deptId = dept['id'].toString();
        _departmentCache[deptId] = dept['name'];
      }
      print("📋 Departman cache güncellendi: ${_departmentCache.length} departman");
    } catch (e) {
      print('❌ Departman cache güncellenirken hata: $e');
    }
  }

  Future<void> fetchActiveJobs() async {
    await fetchAllJobs();
  }

  Future<void> fetchPendingJobs({String? departmentId}) async {
    try {
      print("⏳ Onay bekleyen işler yenileniyor...");
      final pendingResponse = await _client.rpc('get_pending_approval_jobs');
      _pendingJobs = List<Map<String, dynamic>>.from(pendingResponse ?? []);
      
      // Departman adlarını cache'den ekle
      for (var job in _pendingJobs) {
        if (job['department_id'] != null) {
          final deptId = job['department_id'].toString();
          if (_departmentCache.containsKey(deptId)) {
            job['dept_name'] = _departmentCache[deptId];
          } else {
            job['dept_name'] = 'Bilinmeyen Departman';
          }
        } else {
          job['dept_name'] = 'Departman Atanmamış';
        }
      }
      
      print("✅ Onay bekleyen işler yenilendi: ${_pendingJobs.length} adet.");
      notifyListeners();
    } catch (e) {
      print('❌ Onay bekleyen işler yüklenirken hata: $e');
    }
  }
  
  void invalidateCache() {
    _lastFetchTime = null;
    print("🗑️ Cache temizlendi");
  }

  /// İŞİ ONAYLA - Ana fonksiyon
  Future<bool> approveJob(int jobId) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        return false;
      }
      
      final updateData = {
        'status': 'Bitmiş',
        'approved_by': currentUser.id,
        'approved_at': DateTime.now().toIso8601String(),
      };
      
      // İşi onayla
      await _client
          .from('jobs')
          .update(updateData)
          .eq('id', jobId);
      
      // Cache'i invalidate et ve listeleri yenile
      invalidateCache();
      await fetchAllJobs(forceRefresh: true);
      return true;
    } catch (e) {
      print('❌ İş onaylanırken hata: $e');
      return false;
    }
  }

  Future<void> deleteJobs(List<int> jobIds) async {
    if (jobIds.isEmpty) return;
    try {
      print("🗑️ ${jobIds.length} adet iş siliniyor: $jobIds");
      await _client.from('jobs').delete().filter('id', 'in', jobIds);
      
      // Cache'i invalidate et ve listeleri yenile
      invalidateCache();
      await fetchAllJobs(forceRefresh: true);
      print("✅ Seçilen işler başarıyla silindi.");
    } catch (e) {
      print('❌ İşler silinirken hata: $e');
      rethrow;
    }
  }
  
  void _calculateMyJobCount() {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) {
      _myActiveJobCount = 0;
    } else {
      _myActiveJobCount = _activeJobs.where((job) => job['assigned_to'] == currentUserId).length;
    }
    // print("📊 Bana atanan aktif iş sayısı hesaplandı: $_myActiveJobCount");
  }

  /// Departman bazlı iş istatistiklerini getir
  Map<String, int> getDepartmentJobStats() {
    Map<String, int> stats = {};
    
    // Bitmiş işleri departmanlara göre grupla
    for (var job in _completedJobs) {
      final deptName = job['dept_name'] ?? 'Departman Atanmamış';
      stats[deptName] = (stats[deptName] ?? 0) + 1;
    }
    
    // Onay bekleyen işleri de departmanlara göre grupla (tamamlanmış sayılır)
    for (var job in _pendingJobs) {
      final deptName = job['dept_name'] ?? 'Departman Atanmamış';
      stats[deptName] = (stats[deptName] ?? 0) + 1;
    }
    
    print("📊 Departman istatistikleri: $stats");
    return stats;
  }

  /// Departman listesini getir
  List<Map<String, dynamic>> getDepartmentList() {
    return _departmentCache.entries.map((entry) => {
      'id': entry.key,
      'name': entry.value,
    }).toList();
  }
}