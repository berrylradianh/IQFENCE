class UserModel {
  final String? id; // Changed to nullable
  final String email;
  final String role;
  final String? displayName;
  final String? photoURL;
  final String? phoneNumber;
  final String? address;

  UserModel({
    this.id, // Nullable
    required this.email,
    required this.role,
    this.displayName,
    this.photoURL,
    this.phoneNumber,
    this.address,
  });

  String capitalize(String text) {
    if (text.isEmpty) {
      return text;
    }

    return text.split(' ').map((word) {
      final String firstLetter = word.isNotEmpty ? word[0].toUpperCase() : '';
      final String remainingLetters = word.length > 1 ? word.substring(1) : '';
      return '$firstLetter$remainingLetters';
    }).join(' ');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'displayName': displayName != null
          ? capitalize(displayName!)
          : null, // Safe handling
      'photoURL': photoURL,
      'phoneNumber': phoneNumber,
      'address': address,
    };
  }

  factory UserModel.fromJson(String? id, Map<String, dynamic> data) {
    // Nullable id parameter
    return UserModel(
      id: id,
      email: data['email'] ?? '',
      role: data['role'] ?? '',
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      phoneNumber: data['phoneNumber'],
      address: data['address'],
    );
  }
}
