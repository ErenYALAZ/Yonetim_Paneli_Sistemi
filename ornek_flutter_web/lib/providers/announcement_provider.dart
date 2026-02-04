import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/widgets.dart';
import 'dart:typed_data';
import 'dart:math';

class AnnouncementProvider with ChangeNotifier {
  final SupabaseClient _supabase;
  List<Map<String, dynamic>> _announcements = [];
  bool _isLoading = false;
  String? _currentUserId;
  // Cache yönetimi için timestamp
  DateTime? _lastFetchTime;
  static const Duration _cacheValidDuration = Duration(minutes: 2);

  AnnouncementProvider(this._supabase) {
    _currentUserId = _supabase.auth.currentUser?.id;
    // Provider oluşturulduğunda duyuruları çek ve değişiklikleri dinle
    fetchAnnouncements();
    _listenToChanges();
  }

  // Kullanıcı değiştiğinde state'i temizle
  void clearUserData() {
    print('🧹 Kullanıcı verisi temizleniyor...');
    _announcements.clear();
    _isLoading = false;
    _lastFetchTime = null;
    notifyListeners();
  }

  // Yeni kullanıcı için veri yükle
  void initializeForUser() {
    final newUserId = _supabase.auth.currentUser?.id;
    if (_currentUserId != newUserId) {
      print('🔄 Kullanıcı değişti: $_currentUserId -> $newUserId');
      clearUserData();
      _currentUserId = newUserId;
      if (newUserId != null) {
        fetchAnnouncements();
      }
    }
  }

  List<Map<String, dynamic>> get announcements => _announcements;
  bool get isLoading => _isLoading;

  // Okunmamış duyuru sayısını hesapla - cache'den çalışır
  int get unreadCount {
    return _announcements.where((ann) => !(ann['is_seen'] ?? false)).length;
  }

  // Cache kontrolü ile veri getir
  bool get _isCacheValid {
    if (_lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < _cacheValidDuration;
  }

  void _listenToChanges() {
    // Supabase Realtime API'nin güncel ve doğru kullanımı
    _supabase
        .channel('public:announcements')
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'announcements',
            callback: (payload) {
      print('📢 Duyuru değişikliği algılandı! Cache temizleniyor...');
      _lastFetchTime = null; // Cache'i invalid et
      fetchAnnouncements();
    }).subscribe();

    _supabase
        .channel('public:announcement_seen_status')
        .onPostgresChanges(
            event: PostgresChangeEvent.insert, // Sadece yeni eklemeleri dinle
            schema: 'public',
            table: 'announcement_seen_status',
            callback: (payload) {
      print('👁️ Görülme durumu değişikliği algılandı! Cache temizleniyor...');
      _lastFetchTime = null; // Cache'i invalid et
      fetchAnnouncements();
    }).subscribe();
  }

  Future<void> fetchAnnouncements({bool forceRefresh = false}) async {
    // Kullanıcı değişimi kontrol et
    initializeForUser();
    
    // Cache kontrol et
    if (!forceRefresh && _isCacheValid && _announcements.isNotEmpty) {
      print('📋 Cache geçerli, sunucudan veri çekilmiyor');
      return;
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final data = await _supabase.rpc('get_announcements_with_seen_status');
      _announcements = List<Map<String, dynamic>>.from(data);
      _lastFetchTime = DateTime.now();
      print('✅ ${_announcements.length} duyuru yüklendi (Kullanıcı: $_currentUserId)');
      print('📊 Okunmamış duyuru sayısı: $unreadCount');
    } catch (e) {
      print('❌ Duyurular çekilirken hata: $e');
      _lastFetchTime = null; // Hata durumunda cache'i invalid et
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> _uploadImage(Uint8List imageBytes, String fileName) async {
    try {
      // Benzersiz dosya adı oluştur
      final String uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}_$fileName';
      
      // Supabase Storage'a yükle
      await _supabase.storage
          .from('announcement-images')
          .uploadBinary(uniqueFileName, imageBytes);

      // Public URL'i al
      final String publicUrl = _supabase.storage
          .from('announcement-images')
          .getPublicUrl(uniqueFileName);

      return publicUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Dosya adını temizleyen yardımcı fonksiyon
  String _sanitizeFileName(String fileName) {
    // Türkçe karakterleri değiştir
    String sanitized = fileName
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ı', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('Ğ', 'G')
        .replaceAll('Ü', 'U')
        .replaceAll('Ş', 'S')
        .replaceAll('İ', 'I')
        .replaceAll('Ö', 'O')
        .replaceAll('Ç', 'C');
    
    // Özel karakterleri kaldır, sadece harfler, sayılar, nokta ve alt çizgi bırak
    sanitized = sanitized.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    
    // Çoklu alt çizgileri tek alt çizgiye dönüştür
    sanitized = sanitized.replaceAll(RegExp(r'_+'), '_');
    
    // Başında ve sonunda alt çizgi varsa kaldır
    sanitized = sanitized.replaceAll(RegExp(r'^_+|_+$'), '');
    
    return sanitized;
  }

  Future<void> addAnnouncement(
      String title, String content, List<Uint8List>? imageBytesList, List<String>? imageNames) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Duyuru eklemek için giriş yapmış olmalısınız.');
      }
      print("📢 [addAnnouncement] Başladı. Başlık: $title");

      List<String> imageUrls = [];
      if (imageBytesList != null && imageNames != null && imageBytesList.length == imageNames.length) {
        print("🖼️ [addAnnouncement] ${imageBytesList.length} adet görsel işlenecek.");
        for (int i = 0; i < imageBytesList.length; i++) {
          final imageBytes = imageBytesList[i];
          final sanitizedImageName = _sanitizeFileName(imageNames[i]);
          final imagePath = 'announcements/${user.id}/${DateTime.now().millisecondsSinceEpoch}-$sanitizedImageName';
          print("  - [addAnnouncement] Görsel $i yükleniyor: $imagePath");
          
          await _supabase.storage
              .from('announcement-images')
              .uploadBinary(
            imagePath,
            imageBytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );
          print("  - [addAnnouncement] Görsel $i yüklendi.");

          final imageUrl = _supabase.storage
              .from('announcement-images')
              .getPublicUrl(imagePath);
          imageUrls.add(imageUrl);
          print("  - [addAnnouncement] Public URL alındı: $imageUrl");
        }
      } else {
        print("ℹ️ [addAnnouncement] Yüklenecek görsel bulunamadı.");
      }

       final insertData = {
        'title': title,
        'content': content,
        'user_id': user.id,
        'image_url': imageUrls.isNotEmpty ? imageUrls : null,
      };

      print("💾 [addAnnouncement] Veritabanına kaydediliyor: $insertData");
      await _supabase.from('announcements').insert(insertData);
      print("✅ [addAnnouncement] Veritabanına kaydedildi.");


      fetchAnnouncements(); // Re-fetch all announcements
    } catch (e) {
      print('Duyuru eklenirken HATA: $e');
      rethrow;
    }
  }

  Future<void> deleteAnnouncement(int announcementId, List<String> imageUrls) async {
    try {
      print('🗑️ [deleteAnnouncement] Basladi. ID: $announcementId, Gorsel sayisi: ${imageUrls.length}');
      
              // Storage'dan gorselleri sil
      if (imageUrls.isNotEmpty) {
        List<String> pathsToRemove = [];
        for (String url in imageUrls) {
          // URL'den storage path'ini çıkar
          if (url.contains('/announcement-images/')) {
            final path = url.split('/announcement-images/').last;
            pathsToRemove.add(path);
            print('  - [deleteAnnouncement] Silinecek path: $path');
          }
        }
        
        if (pathsToRemove.isNotEmpty) {
          print('🗑️ [deleteAnnouncement] Storage\'dan ${pathsToRemove.length} gorsel siliniyor...');
          await _supabase.storage.from('announcement-images').remove(pathsToRemove);
          print('✅ [deleteAnnouncement] Storage\'dan gorseller silindi.');
        }
      }

              // Veritabanindan duyuruyu sil
      print('🗑️ [deleteAnnouncement] Veritabanindan duyuru siliniyor...');
      await _supabase.from('announcements').delete().match({'id': announcementId});
      print('✅ [deleteAnnouncement] Veritabanindan duyuru silindi.');
      
      // Local state'i güncelle
      _announcements.removeWhere((ann) => ann['id'] == announcementId);
      notifyListeners();
      print('✅ [deleteAnnouncement] Tamamlandi.');
    } catch (e) {
      print('❌ [deleteAnnouncement] Hata: $e');
      rethrow;
    }
  }

  Future<void> markAsSeen(String announcementId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Önce local state'i güncelle (optimistic update)
      final announcementIndex = _announcements.indexWhere((ann) => ann['id'].toString() == announcementId);
      if (announcementIndex != -1) {
        _announcements[announcementIndex]['is_seen'] = true;
        notifyListeners(); // UI'ı hemen güncelle
      }

      // Sonra server'a gönder
      await _supabase.from('announcement_seen_status').upsert({
        'announcement_id': int.parse(announcementId),
        'user_id': userId,
      }, onConflict: 'announcement_id, user_id');
      
      print('✅ Duyuru okundu olarak işaretlendi: $announcementId');
      print('📊 Güncel okunmamış duyuru sayısı: $unreadCount');

      // Cache'i invalid et ve sonraki fetchlerde fresh data alsın
      _lastFetchTime = null;

    } catch (e) {
      // Hata durumunda local state'i geri al
      final announcementIndex = _announcements.indexWhere((ann) => ann['id'].toString() == announcementId);
      if (announcementIndex != -1) {
        _announcements[announcementIndex]['is_seen'] = false;
        notifyListeners();
      }
      
      if (e.toString().contains('violates foreign key constraint')) {
        print('❌ Duyuru artık mevcut değil: $announcementId');
      } else {
        print('❌ Duyuru okunmuş olarak işaretlenirken hata: $e');
      }
    }
  }

  Future<List<Map<String, dynamic>>> getSeenByList(String announcementId) async {
    try {
      final data = await _supabase.rpc('get_users_with_seen_status',
          params: {'ann_id': int.parse(announcementId)});
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Görenler listesi çekilirken hata: $e');
      return [];
    }
  }

  // Tüm kullanıcıları + hangilerinin okuduğu bilgisiyle getiren yeni metod
  Future<List<Map<String, dynamic>>> getAllUsersWithSeenStatus(String announcementId) async {
    try {
      print('🔍 getAllUsersWithSeenStatus çağrıldı, announcement_id: $announcementId');
      final data = await _supabase.rpc('get_all_users_with_seen_status',
          params: {'ann_id': int.parse(announcementId)});
      print('📊 SQL fonksiyonundan dönen veri: $data');
      final result = List<Map<String, dynamic>>.from(data);
      print('✅ İşlenmiş sonuç: $result');
      return result;
    } catch (e) {
      print('❌ Tüm kullanıcılar listesi çekilirken hata: $e');
      return [];
    }
  }
} 