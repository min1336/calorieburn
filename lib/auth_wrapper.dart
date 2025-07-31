// lib/auth_wrapper.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'main_app_screen.dart'; // 새로운 메인 앱 화면 파일

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<User?>();

    if (firebaseUser != null) {
      // 사용자가 로그인 상태이면 메인 앱 화면을 보여줌
      return const MainAppScreen();
    }
    // 사용자가 로그아웃 상태이면 로그인 화면을 보여줌
    return const LoginScreen();
  }
}