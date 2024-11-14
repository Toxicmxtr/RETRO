import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blueGrey,
            ),
            SizedBox(height: 24),
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                labelText: 'Номер телефона или id',
                hintText: 'Например: @prilozh',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Пароль',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/forgot-password');
              },
              child: Text('Я не помню свой пароль'),
            ),
            ElevatedButton(
              onPressed: () {
                // Добавьте логику для авторизации
              },
              child: Text('Войти'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
              child: Text('Нет аккаунта? Зарегистрироваться'),
            ),
          ],
        ),
      ),
    );
  }
}
