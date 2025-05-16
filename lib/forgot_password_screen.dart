import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Импортируем для работы с HTTP запросами
import 'home_screen.dart'; // Импортируем ваш главный экран
import 'dart:convert'; // Для кодирования и декодирования JSON

class ForgotPasswordScreen extends StatelessWidget {
  final TextEditingController usernameController = TextEditingController();

  // Предопределенные учетные данные для тестового аккаунта
  final String testUsername = '@testuser';

  Future<void> _login(BuildContext context) async {
    final String username = usernameController.text;

    // Отправляем запрос на сервер
    try {
      final response = await http.post(
        Uri.parse('http://89.104.66.135:3000/forgot'), // Адрес вашего сервера
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'identifier': username, // Отправляем либо номер телефона, либо user_acctag
        }),
      );

      if (response.statusCode == 200) {
        // Если запрос успешен, получаем user_id
        final Map<String, dynamic> data = json.decode(response.body);
        String userId = data['user_id']?.toString() ?? ''; // Преобразуем в строку

        // Переход на главный экран после успешного входа
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(userId: userId), // Передаем user_id
          ),
        );
      } else {
        // Если ошибка на сервере
        final Map<String, dynamic> data = json.decode(response.body);
        _showErrorDialog(context, data['message']?.toString() ?? 'Неизвестная ошибка');
      }
    } catch (error) {
      // Если произошла ошибка при отправке запроса
      _showErrorDialog(context, 'Ошибка при подключении к серверу');
    }
  }

  // Функция для отображения ошибки
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Ошибка входа'),
          content: Text(message),
          backgroundColor: Color(0xFF111111), // Фон для всплывающего окна
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white, // Белый фон для кнопки
                foregroundColor: Colors.black, // Черный текст на кнопке
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Черный фон
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: () => _showInfoDialog(context), // Открываем всплывающее окно при нажатии на кружок
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white, // Белый цвет для кружка
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        'Ретр0', // Новый текст внутри круга
                        style: TextStyle(
                          fontSize: 30, // Размер шрифта
                          color: Colors.black, // Черный цвет текста
                          fontWeight: FontWeight.w900, // Более жирный шрифт
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    labelText: 'Номер телефона или id',
                    hintText: 'Например: @prilozh',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white), // Белая обводка
                    ),
                    labelStyle: TextStyle(color: Colors.white), // Белый цвет для текста метки
                    hintStyle: TextStyle(color: Colors.white), // Белый цвет для подсказки
                  ),
                  style: TextStyle(color: Colors.white), // Белый цвет текста
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    _login(context); // Вызов функции для входа
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, // Белый цвет фона кнопки
                    foregroundColor: Colors.black, // Черный цвет текста на кнопке
                  ),
                  child: Text('Войти'),
                ),
              ],
            ),
          ),
          // Стрелка для перехода на экран логина в левом верхнем углу
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 16.0, left: 16.0), // Отступы сверху и слева
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back, // Стрелка назад
                  color: Colors.white, // Белый цвет стрелки
                ),
                onPressed: () {
                  Navigator.pop(context); // Возвращаемся назад на экран логина
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Функция для отображения информационного окна
  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Color(0xFF111111), // Цвет фона всплывающего окна
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
                      color: Colors.white, // Белый цвет текста
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
                      color: Colors.white, // Белый цвет текста
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
                        backgroundColor: Colors.white, // Белый цвет фона кнопки
                        foregroundColor: Colors.black, // Черный цвет для текста кнопки
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
}
