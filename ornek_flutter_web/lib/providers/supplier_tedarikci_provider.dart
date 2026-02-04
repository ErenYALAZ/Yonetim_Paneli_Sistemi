import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mime/mime.dart';
import '../models/supplier_tedarikci_model.dart';
import '../main.dart';

class SupplierTedarikciProvider with ChangeNotifier {
  List<SupplierTedarikci> _suppliers = [];
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _bucketName = 'supplieravatars';
  bool _isLoading = false;

  List<SupplierTedarikci> get suppliers => [..._suppliers];
  bool get isLoading => _isLoading;

  Future<void> fetchAndSetSuppliers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase.from('suppliers_tedarikci').select();
      
      final List<dynamic> data = response as List<dynamic>;
      _suppliers = data.map((item) => SupplierTedarikci.fromMap(item)).toList();
      
    } catch (error) {
      debugPrint("---!!! HATA: Tedarikçiler getirilirken bir sorun oluştu !!!---");
      debugPrint("Hata Mesajı: $error");
      _suppliers = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSupplier(SupplierTedarikci supplier, XFile? imageFile) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception("Kullanıcı girişi yapılmamış.");
    }
    
    debugPrint("--- Tedarikçi ekleme işlemi başladı ---");

    try {
      String? imageUrl;
      if (imageFile != null) {
        debugPrint("Resim dosyası bulundu, yükleme deneniyor...");
        final String fileName = '${DateTime.now().toIso8601String()}_${imageFile.name}';
        debugPrint("Yüklenecek bucket: $_bucketName, Dosya adı: $fileName");

        final bytes = await imageFile.readAsBytes();
        
        await _supabase.storage.from(_bucketName).uploadBinary(
              fileName,
              bytes,
              fileOptions: FileOptions(
                upsert: true,
                contentType: imageFile.mimeType ?? 'image/jpeg',
              ),
            );

        imageUrl = _supabase.storage.from(_bucketName).getPublicUrl(fileName);
        debugPrint("Resim başarıyla yüklendi. URL: $imageUrl");
      }

      final newSupplier = SupplierTedarikci(
        id: '', // Supabase will generate this
        userId: user.id,
        companyName: supplier.companyName,
        supplierName: supplier.supplierName,
        contactEmail: supplier.contactEmail,
        contactPhone: supplier.contactPhone,
        profileImageUrl: imageUrl,
        createdAt: DateTime.now(),
      );

      final response = await _supabase
          .from('suppliers_tedarikci')
          .insert(newSupplier.toMap())
          .select()
          .single();

      final createdSupplier = SupplierTedarikci.fromMap(response);
      _suppliers.add(createdSupplier);
      debugPrint("Veritabanına kayıt başarılı.");
      notifyListeners();

    } catch (error, stackTrace) {
      debugPrint("---!!! HATA: Tedarikçi eklenirken bir sorun oluştu !!!---");
      debugPrint("Hata Mesajı: $error");
      debugPrint("Hata Detayı (Stack Trace): $stackTrace");
      rethrow;
    }
  }

  Future<void> updateSupplier(
      SupplierTedarikci supplier, XFile? imageFile) async {
    try {
      String? imageUrl = supplier.profileImageUrl;

      // If a new image is provided, upload it and delete the old one.
      if (imageFile != null) {
        // Delete the old image if it exists
        if (supplier.profileImageUrl != null &&
            supplier.profileImageUrl!.isNotEmpty) {
          final oldFileName = Uri.parse(supplier.profileImageUrl!).pathSegments.last;
          await _supabase.storage.from(_bucketName).remove([oldFileName]);
        }
        
        // Upload the new image
        final String fileName = '${DateTime.now().toIso8601String()}_${imageFile.name}';
        final bytes = await imageFile.readAsBytes();
        await _supabase.storage.from(_bucketName).uploadBinary(
              fileName,
              bytes,
              fileOptions: FileOptions(
                upsert: true,
                contentType: imageFile.mimeType ?? 'image/jpeg',
              ),
            );
        imageUrl = _supabase.storage.from(_bucketName).getPublicUrl(fileName);
      }

      final updatedData = {
        'company_name': supplier.companyName,
        'supplier_name': supplier.supplierName,
        'contact_email': supplier.contactEmail,
        'contact_phone': supplier.contactPhone,
        'profile_image_url': imageUrl,
      };

      final response = await _supabase
          .from('suppliers_tedarikci')
          .update(updatedData)
          .eq('id', supplier.id)
          .select()
          .single();
      
      final updatedSupplier = SupplierTedarikci.fromMap(response);

      final index = _suppliers.indexWhere((s) => s.id == supplier.id);
      if (index != -1) {
        _suppliers[index] = updatedSupplier;
        notifyListeners();
      }
    } catch (error, stackTrace) {
      debugPrint("---!!! HATA: Tedarikçi güncellenirken bir sorun oluştu !!!---");
      debugPrint("Hata Mesajı: $error");
      debugPrint("Hata Detayı (Stack Trace): $stackTrace");
      rethrow;
    }
  }

  Future<void> deleteSupplier(String supplierId, String? imageUrl) async {
    try {
      // Delete the image from storage if it exists
      if (imageUrl != null && imageUrl.isNotEmpty) {
        final fileName = Uri.parse(imageUrl).pathSegments.last;
        await _supabase.storage.from(_bucketName).remove([fileName]);
      }

      // Delete the supplier from the database
      await _supabase.from('suppliers_tedarikci').delete().eq('id', supplierId);

      // Remove from local list
      _suppliers.removeWhere((supplier) => supplier.id == supplierId);
      notifyListeners();
      
    } catch (error, stackTrace) {
      debugPrint("---!!! HATA: Tedarikçi silinirken bir sorun oluştu !!!---");
      debugPrint("Hata Mesajı: $error");
      debugPrint("Hata Detayı (Stack Trace): $stackTrace");
      rethrow;
    }
  }
} 