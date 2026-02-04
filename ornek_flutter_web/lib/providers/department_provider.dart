import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Departman modelini, bu dosyada tanımlayarak merkezi bir hale getiriyoruz.
class Department {
  final String id;
  final String name;
  final String colorHex;

  Department({required this.id, required this.name, required this.colorHex});

  // Veritabanından gelen JSON verisini Department nesnesine çeviren fabrika metodu.
  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'],
      name: json['name'],
      colorHex: json['color_hex'] ?? '#8892B0', // Varsayılan renk
    );
  }
}

// Departman listesini yöneten Provider.
class DepartmentProvider with ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;
  List<Department> _departments = [];
  bool _isLoading = false;

  List<Department> get departments => _departments;
  bool get isLoading => _isLoading;

  // Provider oluşturulduğunda departmanları otomatik olarak çeker.
  DepartmentProvider() {
    fetchDepartments();
  }

  Future<void> fetchDepartments() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      // Supabase'den tüm departmanları 'name' alanına göre alfabetik sıralayarak çekiyoruz.
      final response = await _client.from('departments').select().order('name', ascending: true);
      _departments = (response as List).map((dept) => Department.fromJson(dept)).toList();
      print("✅ Departmanlar filtre için çekildi: ${_departments.length} adet.");
    } catch (e) {
      print('❌ Departmanlar yüklenirken hata: $e');
      _departments = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 