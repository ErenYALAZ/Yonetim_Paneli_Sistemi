class UserPermission {
  final String id;
  final String userId;
  final String permissionType;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserPermission({
    required this.id,
    required this.userId,
    required this.permissionType,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserPermission.fromJson(Map<String, dynamic> json) {
    return UserPermission(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      permissionType: json['permission_type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'permission_type': permissionType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsert() {
    return {
      'user_id': userId,
      'permission_type': permissionType,
    };
  }
}

// Yetki türleri için sabitler
class PermissionTypes {
  static const String duyuru = 'duyuru';
  static const String kontrolPaneli = 'kontrol_paneli';
  static const String tedarikciPaneli = 'tedarikci_paneli';
  static const String imalat = 'imalat';
  static const String managementPanelAccess = 'management_panel_access';

  static const List<String> allPermissions = [
    duyuru,
    kontrolPaneli,
    tedarikciPaneli,
    imalat,
    managementPanelAccess,
  ];

  static const Map<String, String> permissionNames = {
    duyuru: 'Duyuru',
    kontrolPaneli: 'Kontrol Paneli',
    tedarikciPaneli: 'Tedarikçi Paneli',
    imalat: 'İmalat',
    managementPanelAccess: 'Yönetim Paneli',
  };

  static const Map<String, String> permissionDescriptions = {
    duyuru: 'Duyuru atabilme ve düzenleyebilme yetkisi',
    kontrolPaneli: 'Kontrol panelini düzenleyebilme yetkisi',
    tedarikciPaneli: 'Tedarikçi listesini yönetebilme yetkisi',
    imalat: 'İmalat süreçlerini onaylayabilme yetkisi',
    managementPanelAccess: 'Yönetim paneline erişim yetkisi',
  };
} 