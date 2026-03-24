class CustomerModel {
  const CustomerModel({required this.id, required this.name, this.phone});

  final String id;
  final String name;
  final String? phone;

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'phone': phone};
  }
}
