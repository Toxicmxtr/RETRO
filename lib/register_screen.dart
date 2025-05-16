import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_screen.dart'; // Импортируйте ваш главный экран
import 'package:flutter/services.dart'; // Этот импорт необходим для работы с FilteringTextInputFormatter и LengthLimitingTextInputFormatter

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  String selectedRegion = 'Россия';
  String phonePrefix = '+7';

  final Map<String, String> regionPrefixes = {
    'Россия': '+7',
    'Беларусь': '+375',
    'Молдова': '+373',
  };

  @override
  void initState() {
    super.initState();
    phoneNumberController.text = '';
  }

  void updatePhonePrefix(String region) {
    setState(() {
      selectedRegion = region;
      phonePrefix = regionPrefixes[region] ?? '+7';
      phoneNumberController.clear(); // Сбрасываем ввод номера при смене региона
    });
  }

  Future<void> registerUser(BuildContext context) async {
    final phoneNumber = phoneNumberController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (password != confirmPassword) {
      _showErrorDialog(context, 'Пароли не совпадают');
      return;
    }

    if (phoneNumber.isEmpty || password.isEmpty) {
      _showErrorDialog(context, 'Заполните все поля');
      return;
    }

    final fullPhoneNumber = phonePrefix + phoneNumber;

    try {
      final response = await http.post(
        Uri.parse('https://retroispk.ru/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_phone_number': fullPhoneNumber,
          'user_password': password,
        }),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final userId = responseData['user_id'].toString();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Регистрация успешна'),
            backgroundColor: Color(0xFF111111),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(userId: userId),
          ),
        );
      } else {
        final responseData = jsonDecode(response.body);
        _showErrorDialog(context, responseData['message'] ?? 'Неизвестная ошибка');
      }
    } catch (error) {
      _showErrorDialog(context, 'Ошибка соединения с сервером');
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Ошибка регистрации'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
            ),
          ],
          backgroundColor: Color(0xFF111111),
        );
      },
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Color(0xFF111111),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ретр0',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Инструмент для ретроспектив, помогающий командам и группам эффективно анализировать прошедшие проекты, '
                        'выявлять сильные и слабые стороны, а также находить пути для улучшения процессов. '
                        'Простой и удобный в использовании, он предоставляет все необходимые инструменты для '
                        'проведения открытых обсуждений и выработки решений, которые помогут двигаться вперёд. '
                        'Вы можете делиться мнениями, фиксировать важные моменты и сохранять выводы для будущих встреч. '
                        'С помощью этого приложения проведение ретроспектив становится быстрым, удобным и результативным.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Разработчик: Губкин Данил Иванович ИСПк-301-51',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('Закрыть'),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: () {
                    _showInfoDialog(context);
                  },
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        'Ретр0',
                        style: TextStyle(
                          fontSize: 30,
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        color: Colors.black,
                        child: DropdownButtonFormField<String>(
                          value: selectedRegion,
                          items: regionPrefixes.keys.map((region) {
                            return DropdownMenuItem(
                              value: region,
                              child: Text(
                                region,
                                style: TextStyle(color: Colors.white),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              updatePhonePrefix(value);
                            }
                          },
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 8),
                            border: OutlineInputBorder(),
                          ),
                          dropdownColor: Color(0xFF111111),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      flex: 7,
                      child: TextField(
                        controller: phoneNumberController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: InputDecoration(
                          prefixText: phonePrefix,
                          border: OutlineInputBorder(),
                          labelStyle: TextStyle(color: Colors.white),
                          hintStyle: TextStyle(color: Colors.white54),
                        ),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Пароль',
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Повторите пароль',
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                  ),
                  onPressed: () {
                    registerUser(context);
                  },
                  child: Text(
                    'Зарегистрироваться',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0, left: 16.0),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}