class Department {
  final String id;
  final String name;
  final String colorHex;

  Department({required this.id, required this.name, required this.colorHex});

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'],
      name: json['name'],
      colorHex: json['color_hex'] ?? '#8892B0', // Varsayılan renk
    );
  }
} 