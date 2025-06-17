import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/Auth.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.placeholder,
    this.isPassword = false,
    this.isPhone = false,
    this.enabled = true,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hintText;
  final String placeholder;
  final bool isPassword;
  final bool isPhone;
  final bool enabled;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Consumer<Auth>(
      builder: (context, value, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              placeholder,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              enabled: enabled,
              controller: controller,
              obscureText: value.isPasswordVisible && isPassword,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                hintText: hintText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: isPassword
                    ? IconButton(
                        onPressed: () {
                          value.togglePasswordVisibility();
                        },
                        icon: Icon(value.isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility),
                      )
                    : null,
                prefixIcon: isPhone
                    ? Container(
                        width: 90, // Fixed width for consistency
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 4.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              margin: const EdgeInsets.only(right: 8.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4.0),
                                child: Image.asset(
                                  'assets/indonesian_flag.png',
                                  width: 24,
                                  height: 16,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Text(
                              '+62',
                              style: TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Container(
                              width: 1,
                              height: 24,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                      )
                    : null,
              ),
            ),
          ],
        );
      },
    );
  }
}
