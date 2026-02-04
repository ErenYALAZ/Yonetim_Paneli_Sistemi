import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ornek_flutter_web/services/auth_service.dart';
import 'package:provider/provider.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  String _testResult = 'Test henüz çalıştırılmadı';
  bool _isLoading = false;

  Future<void> _testCurrentUser() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Kullanıcı bilgileri kontrol ediliyor...';
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _testResult = '❌ Kullanıcı giriş yapmamış!';
        });
        return;
      }

      // Profil bilgilerini çek
      final profileData = await Supabase.instance.client
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .maybeSingle();

      // AuthService durumunu kontrol et
      final authService = Provider.of<AuthService>(context, listen: false);
      
      String result = '=== KULLANICI BİLGİLERİ ===\n';
      result += 'Email: ${user.email}\n';
      result += 'User ID: ${user.id}\n\n';
      
      result += '=== PROFİL VERİTABANI ===\n';
      if (profileData != null) {
        result += 'Username: ${profileData['username'] ?? 'Yok'}\n';
        result += 'Role: ${profileData['role'] ?? 'Yok'}\n';
        result += 'Department ID: ${profileData['department_id'] ?? 'Yok'}\n';
      } else {
        result += 'Profil verisi bulunamadı!\n';
      }
      
      result += '\n=== AUTH SERVICE DURUMU ===\n';
      result += 'AuthService Role: ${authService.userRole ?? 'Yok'}\n';
      result += 'AuthService Department ID: ${authService.userDepartmentId ?? 'Yok'}\n';
      result += 'isAdmin(): ${authService.isAdmin()}\n';
      result += 'isManager(): ${authService.isManager()}\n';
      result += 'isReady: ${authService.isReady}\n';

      // Özel hesapoyuneren@hotmail.com kontrolü
      if (user.email == 'hesapoyuneren@hotmail.com') {
        result += '\n=== ÖZEL KONTROL ===\n';
        result += '✅ Bu hesapoyuneren@hotmail.com hesabı!\n';
        
        if (profileData != null && profileData['role']?.toString().toLowerCase() == 'admin') {
          result += '✅ Veritabanında admin rolü var\n';
          if (!authService.isAdmin()) {
            result += '❌ AMA AuthService admin olarak görmüyor!\n';
            result += '🔧 AuthService yenileme gerekiyor...\n';
          }
        } else {
          result += '❌ Veritabanında admin rolü YOK!\n';
        }
      }

      setState(() {
        _testResult = result;
      });

    } catch (e) {
      setState(() {
        _testResult = '❌ Hata oluştu: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fixAdminRole() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Admin rolü düzeltiliyor...';
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _testResult = '❌ Kullanıcı giriş yapmamış!';
        });
        return;
      }

      // Rolü admin olarak güncelle
      final response = await Supabase.instance.client
          .from('profiles')
          .update({'role': 'admin'})
          .eq('id', user.id)
          .select();

      if (response.isNotEmpty) {
        // AuthService'i yenile
        final authService = Provider.of<AuthService>(context, listen: false);
        await Future.delayed(Duration(milliseconds: 500)); // Kısa bekle
        
        setState(() {
          _testResult = '✅ Admin rolü güncellendi!\n';
          _testResult += 'AuthService otomatik yenilenecek...\n';
          _testResult += 'Sayfa yenilendikten sonra yetkilerin aktif olacak.';
        });
      } else {
        setState(() {
          _testResult = '❌ Rol güncellenemedi - RLS sorunu olabilir';
        });
      }

    } catch (e) {
      setState(() {
        _testResult = '❌ Hata oluştu: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createDefaultDepartments() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Varsayılan departmanlar oluşturuluyor...';
    });

    try {
      final defaultDepartments = [
        {'name': 'Arge', 'color_hex': '#FF6B6B'},      // Kırmızı
        {'name': 'İmalat', 'color_hex': '#4ECDC4'},    // Turkuaz
        {'name': 'Saha', 'color_hex': '#45B7D1'},      // Mavi
        {'name': 'Tasarım', 'color_hex': '#96CEB4'},   // Yeşil
        {'name': 'Elektrik', 'color_hex': '#FECA57'},  // Sarı
      ];

      String result = '=== DEPARTMAN OLUŞTURMA SONUÇLARI ===\n\n';

      for (final dept in defaultDepartments) {
        try {
          // Önce bu departmanın zaten var olup olmadığını kontrol et
          final existingDept = await Supabase.instance.client
              .from('departments')
              .select('id, name')
              .eq('name', dept['name']!)
              .maybeSingle();

          if (existingDept != null) {
            result += '⚠️ ${dept['name']} departmanı zaten mevcut (ID: ${existingDept['id']})\n';
          } else {
            // Departmanı oluştur
            final response = await Supabase.instance.client
                .from('departments')
                .insert(dept)
                .select();

            if (response.isNotEmpty) {
              result += '✅ ${dept['name']} departmanı oluşturuldu (Renk: ${dept['color_hex']})\n';
            } else {
              result += '❌ ${dept['name']} departmanı oluşturulamadı\n';
            }
          }
        } catch (e) {
          result += '❌ ${dept['name']} departmanı oluşturulurken hata: $e\n';
        }
      }

      result += '\n=== ÖZETleme ===\n';
      result += 'Artık rol atama ekranında departman seçimi yapabilirsiniz!\n';
      result += 'Her departmanın kendine özel rengi vardır.\n';

      setState(() {
        _testResult = result;
      });

    } catch (e) {
      setState(() {
        _testResult = '❌ Genel hata oluştu: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshAuthService() async {
    setState(() {
      _isLoading = true;
      _testResult = 'AuthService yenileniyor...';
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.refreshUserData();
      
      // Yenileme sonrası kontrol et
      String result = '🔄 AuthService yenilendi!\n\n';
      result += '=== GÜNCEL AUTH SERVICE DURUMU ===\n';
      result += 'AuthService Role: ${authService.userRole ?? 'Yok'}\n';
      result += 'AuthService Department ID: ${authService.userDepartmentId ?? 'Yok'}\n';
      result += 'isAdmin(): ${authService.isAdmin()}\n';
      result += 'isManager(): ${authService.isManager()}\n';
      result += 'isReady: ${authService.isReady}\n';

      setState(() {
        _testResult = result;
      });

    } catch (e) {
      setState(() {
        _testResult = '❌ AuthService yenileme hatası: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _switchUserDepartment(String departmentName) async {
    setState(() {
      _isLoading = true;
      _testResult = 'Kullanıcı departmanı değiştiriliyor...';
    });

    try {
      String result = '=== KULLANICI DEPARTMANI DEĞİŞTİRME ===\n\n';

      // Departman ID'sini al
      final departmentResponse = await Supabase.instance.client
          .from('departments')
          .select('id, name')
          .eq('name', departmentName)
          .single();

      final departmentId = departmentResponse['id'];
      final currentUserId = Supabase.instance.client.auth.currentUser!.id;

      // Kullanıcının departmanını güncelle
      await Supabase.instance.client
          .from('profiles')
          .update({
            'department_id': departmentId,
          })
          .eq('id', currentUserId);

      result += '✅ Kullanıcı departmanı $departmentName olarak güncellendi!\n';
      result += 'Artık $departmentName departmanında iş ekleyebilirsiniz.\n';
      result += '\nYeni iş ekledikten sonra dashboard\'da grafikleri kontrol edin.\n';

      setState(() {
        _testResult = result;
      });

    } catch (e) {
      setState(() {
        _testResult = '❌ Departman değiştirme hatası: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createTestUsers() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Test kullanıcıları oluşturuluyor...';
    });

    try {
      String result = '=== TEST KULLANICILARI OLUŞTURMA ===\n\n';

      // Önce departmanları al
      final departmentsResponse = await Supabase.instance.client
          .from('departments')
          .select('id, name');

      if (departmentsResponse.isEmpty) {
        result += '❌ Önce departmanları oluşturun!\n';
        setState(() {
          _testResult = result;
        });
        return;
      }

      final departments = Map<String, String>.fromEntries(
        departmentsResponse.map((dept) => MapEntry(dept['name'] as String, dept['id'] as String))
      );

      // Test kullanıcıları için departman atamaları
      final testUsers = [
        {'email': 'imalat@test.com', 'username': 'İmalat Kullanıcısı', 'department': 'İmalat'},
        {'email': 'saha@test.com', 'username': 'Saha Kullanıcısı', 'department': 'Saha'},
        {'email': 'tasarim@test.com', 'username': 'Tasarım Kullanıcısı', 'department': 'Tasarım'},
        {'email': 'arge2@test.com', 'username': 'Arge Kullanıcısı 2', 'department': 'Arge'},
        {'email': 'elektrik2@test.com', 'username': 'Elektrik Kullanıcısı 2', 'department': 'Elektrik'},
      ];

      for (final user in testUsers) {
        try {
          final departmentId = departments[user['department']];
          if (departmentId == null) {
            result += '❌ ${user['department']} departmanı bulunamadı!\n';
            continue;
          }

          // Kullanıcının zaten var olup olmadığını kontrol et
          final existingProfile = await Supabase.instance.client
              .from('profiles')
              .select('id, username')
              .eq('username', user['username']!)
              .maybeSingle();

          if (existingProfile != null) {
            // Mevcut kullanıcının departmanını güncelle
            await Supabase.instance.client
                .from('profiles')
                .update({
                  'department_id': departmentId,
                  'role': 'user'
                })
                .eq('id', existingProfile['id']);
            
            result += '✅ ${user['username']} -> ${user['department']} (güncellendi)\n';
          } else {
            // Yeni profil oluştur (gerçek auth kullanıcısı olmadan)
            final newProfile = await Supabase.instance.client
                .from('profiles')
                .insert({
                  'id': Supabase.instance.client.auth.currentUser!.id, // Geçici olarak mevcut kullanıcı ID'si
                  'username': user['username'],
                  'department_id': departmentId,
                  'role': 'user'
                })
                .select()
                .single();
            
            result += '✅ ${user['username']} -> ${user['department']} (oluşturuldu)\n';
          }
        } catch (e) {
          result += '❌ ${user['username']} oluşturulurken hata: $e\n';
        }
      }

      result += '\n=== ÖZETleme ===\n';
      result += 'Test kullanıcıları oluşturuldu!\n';
      result += 'Artık farklı departmanlarda iş ekleyebilirsiniz.\n';

      setState(() {
        _testResult = result;
      });

    } catch (e) {
      setState(() {
        _testResult = '❌ Genel hata oluştu: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createPermissionsTable() async {
    setState(() {
      _isLoading = true;
      _testResult = 'User permissions tablosu oluşturuluyor...';
    });

    try {
      String result = '=== USER PERMISSIONS TABLOSU OLUŞTURMA ===\n\n';

      // Önce tabloyu kontrol et
      try {
        final testQuery = await Supabase.instance.client
            .from('user_permissions')
            .select('count')
            .limit(1);
        
        result += '⚠️ user_permissions tablosu zaten mevcut!\n';
        result += 'Tablo kontrolü başarıyla geçti.\n\n';
      } catch (e) {
        result += '📋 user_permissions tablosu bulunamadı, oluşturulması gerekiyor.\n\n';
        result += '🔧 SUPABASE SQL EDITOR\'DA ÇALIŞTIRIN:\n\n';
        result += '''-- User Permissions Tablosu
CREATE TABLE user_permissions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  permission_type TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  UNIQUE(user_id, permission_type)
);

-- RLS Politikaları
ALTER TABLE user_permissions ENABLE ROW LEVEL SECURITY;

-- Admin herkesi görebilir
CREATE POLICY "Admins can view all permissions" ON user_permissions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'admin'
    )
  );

-- Kullanıcılar sadece kendi yetkilerini görebilir
CREATE POLICY "Users can view own permissions" ON user_permissions
  FOR SELECT USING (auth.uid() = user_id);

-- Admin yetki ekleyebilir
CREATE POLICY "Admins can insert permissions" ON user_permissions
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'admin'
    )
  );

-- Admin yetki silebilir
CREATE POLICY "Admins can delete permissions" ON user_permissions
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = auth.uid() 
      AND profiles.role = 'admin'
    )
  );

-- Updated at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS \$\$
BEGIN
    NEW.updated_at = TIMEZONE('utc'::text, NOW());
    RETURN NEW;
END;
\$\$ language 'plpgsql';

CREATE TRIGGER update_user_permissions_updated_at BEFORE UPDATE
    ON user_permissions FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();''';
        
        result += '\n\n✅ Bu SQL kodunu Supabase SQL Editor\'da çalıştırdıktan sonra görev atama sistemi çalışacak.';
      }

      setState(() {
        _testResult = result;
      });

    } catch (e) {
      setState(() {
        _testResult = '❌ Tablo kontrol hatası: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color darkNavyBg = Color(0xFF0A192F);
    const Color cardBlue = Color(0xFF172A46);
    const Color lightText = Color(0xFFE0E0E0);

    return Scaffold(
      backgroundColor: darkNavyBg,
      appBar: AppBar(
        title: const Text('Test Ekranı', style: TextStyle(color: lightText)),
        backgroundColor: cardBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: cardBlue,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Kullanıcı Yetki Kontrolü',
                      style: TextStyle(color: lightText, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testCurrentUser,
                      child: _isLoading 
                        ? const CircularProgressIndicator()
                        : const Text('Mevcut Kullanıcıyı Kontrol Et'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _fixAdminRole,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      child: const Text('Admin Rolünü Düzelt'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _createDefaultDepartments,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('Varsayılan Departmanları Oluştur'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _createTestUsers,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                      child: const Text('Test Kullanıcıları Oluştur'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _refreshAuthService,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                      child: const Text('AuthService\'i Yenile'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _createPermissionsTable,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                      child: const Text('User Permissions Tablosu Oluştur'),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Departman Değiştirme (Test İçin)',
                      style: TextStyle(color: lightText, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: _isLoading ? null : () => _switchUserDepartment('İmalat'),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4ECDC4)),
                          child: const Text('İmalat'),
                        ),
                        ElevatedButton(
                          onPressed: _isLoading ? null : () => _switchUserDepartment('Saha'),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF45B7D1)),
                          child: const Text('Saha'),
                        ),
                        ElevatedButton(
                          onPressed: _isLoading ? null : () => _switchUserDepartment('Tasarım'),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF96CEB4)),
                          child: const Text('Tasarım'),
                        ),
                        ElevatedButton(
                          onPressed: _isLoading ? null : () => _switchUserDepartment('Arge'),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B6B)),
                          child: const Text('Arge'),
                        ),
                        ElevatedButton(
                          onPressed: _isLoading ? null : () => _switchUserDepartment('Elektrik'),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFECA57)),
                          child: const Text('Elektrik'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                color: cardBlue,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Test Sonuçları:',
                        style: TextStyle(color: lightText, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              _testResult,
                              style: const TextStyle(
                                color: lightText,
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}