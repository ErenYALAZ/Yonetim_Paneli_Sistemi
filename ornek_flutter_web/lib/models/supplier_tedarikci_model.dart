import 'package:flutter/foundation.dart';

class SupplierTedarikci {
  final String id;
  final String userId;
  final String? companyName;
  final String supplierName;
  final String? contactEmail;
  final String? contactPhone;
  final String? profileImageUrl;
  final DateTime? createdAt;

  SupplierTedarikci({
    required this.id,
    required this.userId,
    this.companyName,
    required this.supplierName,
    this.contactEmail,
    this.contactPhone,
    this.profileImageUrl,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'company_name': companyName,
      'supplier_name': supplierName,
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
      'profile_image_url': profileImageUrl,
      // 'created_at' is handled by Supabase default value
    };
  }

  factory SupplierTedarikci.fromMap(Map<String, dynamic> map) {
    return SupplierTedarikci(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      companyName: map['company_name'] as String?,
      supplierName: map['supplier_name'] as String,
      contactEmail: map['contact_email'] as String?,
      contactPhone: map['contact_phone'] as String?,
      profileImageUrl: map['profile_image_url'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }
} 