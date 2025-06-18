import 'package:flutter/material.dart';
import 'package:iqfence/models/userModel.dart';

class UserDropdown extends StatelessWidget {
  final String? selectedUserId;
  final List<UserModel> users;
  final TextEditingController searchController;
  final ValueChanged<String?> onUserChanged;

  const UserDropdown({
    super.key,
    required this.selectedUserId,
    required this.users,
    required this.searchController,
    required this.onUserChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Pilih User',
            border: OutlineInputBorder(),
          ),
          value: selectedUserId,
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Semua User'),
            ),
            ...users.map((user) => DropdownMenuItem<String>(
                  value: user.email, // Using email as unique ID
                  child: Text(user.displayName ?? 'Unknown'),
                )),
          ],
          onChanged: onUserChanged,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: searchController,
          decoration: const InputDecoration(
            labelText: 'Cari berdasarkan nama user',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
        ),
      ],
    );
  }
}
