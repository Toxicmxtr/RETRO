import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'boards.dart'; // Импортируем boards.dart
import 'login_LDAP.dart';
import 'profile_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Forum App',
      theme: ThemeData.dark(),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(userId: 'some_user_id'.toString()), // Передаем userId как строку
        '/register': (context) => RegisterScreen(),
        '/forgot-password': (context) => ForgotPasswordScreen(),
        '/boards': (context) => BoardsScreen(
          boardId: 1.toString(), // Преобразуем int в строку
          boardName: 'Example Board', // Передаем boardName как строку
          userId: 'some_user_id', // Теперь передаем userId
        ),
        '/ldap-login': (context) => LoginLDAP(),
        '/profile': (context) => ProfileScreen(userId: 'some_user_id'),
      },
    );
  }
}