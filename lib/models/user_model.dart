class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.createdAt,
  });

  // Converte para Map para salvar no Firestore
  Map<String, dynamic> toMap() => {
    'uid': uid,
    'name': name,
    'email': email,
    'phone': phone,
    'createdAt': createdAt.toIso8601String(),
  };

  // Lê um documento do Firestore e transforma em UserModel
  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    uid: map['uid'] ?? '',
    name: map['name'] ?? '',
    email: map['email'] ?? '',
    phone: map['phone'] ?? '',
    createdAt: DateTime.parse(map['createdAt']),
  );
}
