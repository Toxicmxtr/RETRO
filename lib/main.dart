import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Forum App',
      theme: ThemeData.dark(), // Темная тема, как на ваших экранах
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/forgot-password': (context) => ForgotPasswordScreen(),
      },
    );
  }
}
