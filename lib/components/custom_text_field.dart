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
  });

  final TextEditingController controller;
  final String hintText;
  final String placeholder;
  final bool isPassword;
  final bool isPhone;
  final bool enabled;

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
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          //flag image
                          Image.asset(
                            'assets/Indonesia_flag.png',
                          ),
                          const Text(
                            '+62',
                            style: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 1,
                            height: 20,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 10),
                        ],
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