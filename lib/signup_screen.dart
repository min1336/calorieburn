// lib/signup_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/authentication_service.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text("회원가입")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "이메일"),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "비밀번호"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final result = await context.read<AuthenticationService>().signUp(
                  email: emailController.text.trim(),
                  password: passwordController.text.trim(),
                );

                if (!context.mounted) return;

                if (result == "Signed up") {
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result ?? "회원가입 실패"))
                  );
                }
              },
              child: const Text("회원가입"),
            )
          ],
        ),
      ),
    );
  }
}