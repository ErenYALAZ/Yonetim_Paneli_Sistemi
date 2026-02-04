import 'package:flutter/material.dart';

class Role {
  final String id;
  final String name;
  final String? description; // Açıklama alanı eklendi
  final String? parentId;
  final String? departmentId; // Departman ID'si eklendi
  List<Role> children;

  Role({
    required this.id,
    required this.name,
    this.description, // Yapıcıya eklendi
    this.parentId,
    this.departmentId, // Departman ID'si yapıcıya eklendi
    List<Role>? children,
  }) : this.children = children ?? [];

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'],
      name: json['name'],
      description: json['description'], // FromJson'a eklendi
      parentId: json['parent_id'],
      departmentId: json['department_id'], // Departman ID'si fromJson'a eklendi
    );
  }

  Role copyWith({
    String? name,
    String? description, // CopyWith'e eklendi
    String? parentId,
    String? departmentId,
    List<Role>? children,
  }) {
    return Role(
      id: this.id,
      name: name ?? this.name,
      description: description ?? this.description, // Kopyalama mantığı eklendi
      parentId: parentId ?? this.parentId,
      departmentId: departmentId ?? this.departmentId,
      children: children ?? List.from(this.children),
    );
  }

  @override
  String toString() {
    return 'Role(id: $id, name: $name, description: $description, parentId: $parentId, children: ${children.length})';
  }

  // GraphView'in düğümleri doğru bir şekilde karşılaştırabilmesi için eklendi.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Role &&
      other.id == id &&
      other.name == name &&
      other.description == description &&
      other.parentId == parentId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      name.hashCode ^
      description.hashCode ^
      parentId.hashCode;
  }
} 