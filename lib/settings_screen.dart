import 'dart:io'; // Для работы с файлами
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Для работы с FilteringTextInputFormatter
import 'package:image_picker/image_picker.dart'; // Для выбора изображения
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart'; // Импорт экрана для логина
import 'package:http_parser/http_parser.dart';

class SettingsScreen extends StatefulWidget {
  final String userId;

  SettingsScreen({required this.userId});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String userName = "Загрузка...";
  String userIdDisplay = "@Загрузка...";
  String userPhoneNumber = "Загрузка...";
  String? userPhotoUrl;

  TextEditingController nameController = TextEditingController();
  TextEditingController idController = TextEditingController();
  TextEditingController phoneController = TextEditingController();

  String selectedRegion = "+7";  // Регион по умолчанию
  String selectedRegionName = "Россия";  // Название региона

  final Map<String, String> regionPrefixes = {
    'Россия': '+7',
    'Беларусь': '+375',
    'Молдова': '+373',
  };

  @override
  void initState() {
    super.initState();
    fetchUserData(); // Загружаем данные при старте экрана
  }

  Future<void> fetchUserData() async {
    try {
      final response = await http.get(
        Uri.parse('https://retroispk.ru/settings/${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          userName = data['user_name'] ?? "Неизвестный пользователь";
          userIdDisplay = data['user_acctag'] ?? "@Неизвестный";
          userPhoneNumber = data['user_phone_number'] ?? "Неизвестно";
          userPhotoUrl = data['avatar_url']; // Получаем только имя файла
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ошибка загрузки данных")),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка сети")),
      );
    }
  }

  Future<void> updateUserData(String field, String value) async {
    try {
      final Map<String, String> updateData = {};
      if (field == "name" && value.isNotEmpty) updateData['user_name'] = value;
      if (field == "phone" && value.isNotEmpty) {
        value = selectedRegion + value; // Добавляем код региона
        updateData['user_phone_number'] = value;
      }
      if (field == "acctag" && value.isNotEmpty) {
        value = "@$value"; // Добавляем знак @ перед значением
        updateData['user_acctag'] = value;
      }

      if (updateData.isEmpty) {
        return;
      }

      final response = await http.patch(
        Uri.parse('https://retroispk.ru/settings/${widget.userId}'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(updateData),
      );

      if (response.statusCode == 409) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(field == "acctag"
              ? "Такой тэг уже существует, укажите другой"
              : "Номер телефона уже используется")),
        );
      } else if (response.statusCode == 200) {
        setState(() {
          if (field == "name") userName = value;
          if (field == "phone") userPhoneNumber = value;
          if (field == "acctag") userIdDisplay = value;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Данные успешно обновлены")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ошибка обновления данных")),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка сети: данные не обновлены")),
      );
    }
  }

  Future<void> uploadAvatar(File imageFile) async {
    try {
      Uint8List imageBytes = await imageFile.readAsBytes();
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://retroispk.ru/upload-avatar/${widget.userId}'),
      );
      request.files.add(http.MultipartFile.fromBytes(
        'avatar',
        imageBytes,
        filename: imageFile.path.split('/').last,
        contentType: MediaType('image', 'jpeg'),
      ));
      var response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final data = json.decode(responseData);
        setState(() {
          userPhotoUrl = data['user_avatar'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Фото успешно обновлено")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ошибка загрузки фото")),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка сети: фото не загружено")),
      );
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      await uploadAvatar(imageFile);
    }
  }

  Future<void> _deleteAccount() async {
    try {
      final response = await http.delete(
        Uri.parse('https://retroispk.ru/settings/${widget.userId}'),
      );

      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ошибка удаления аккаунта")),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка сети: аккаунт не удален")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Настройки'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Color(0xFF111111), // Установил цвет 111111 для AppBar
      ),
      body: Container(
        color: Colors.black, // Черный фон всего окна
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white, // Кружок теперь белый
                    backgroundImage: userPhotoUrl != null && userPhotoUrl!.isNotEmpty
                        ? NetworkImage('https://retroispk.ru$userPhotoUrl')
                        : null, // Убрали путь к картинке с черным человеком
                  ),
                  IconButton(
                    icon: Icon(Icons.camera_alt, color: Colors.black), // Черная иконка
                    onPressed: pickImage,
                    padding: EdgeInsets.all(0), // Убираем паддинг
                    color: Colors.white, // Белая кнопка
                    iconSize: 30, // Увеличиваем размер иконки
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Text('Изменить имя',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            GestureDetector(
              onTap: () => _editField("Имя пользователя", userName, "name"),
              child: Text(userName, style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
            SizedBox(height: 8),
            Text('Изменить id пользователя',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            GestureDetector(
              onTap: () =>
                  _editField("ID пользователя", userIdDisplay, "acctag"),
              child: Text(userIdDisplay, style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
            SizedBox(height: 8),
            Text('Изменить номер телефона',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            GestureDetector(
              onTap: () => _editPhoneNumber(),
              child: Row(
                children: [
                  Text(userPhoneNumber, style: TextStyle(fontSize: 16, color: Colors.white)),
                ],
              ),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () {
                _confirmDeleteAccount();
              },
              child: Text(
                'Удалить аккаунт',
                style: TextStyle(color: Colors.white),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editField(String title, String currentValue, String field) {
    TextEditingController controller = TextEditingController(
        text: field == "acctag"
            ? currentValue.replaceAll("@", "")
            : currentValue);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color(0xFF111111), // Черный фон окна
          title: Text("Изменить $title", style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            style: TextStyle(color: Colors.white),
            maxLength: field == "acctag" ? 21 : 21, // Изменил на 21
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp('[^a-zA-Zа-яА-Я0-9_]')), // Убрал запрет на русские буквы
            ],
            decoration: InputDecoration(
              hintText: 'Введите новое $title',
              hintStyle: TextStyle(color: Colors.white),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Отмена", style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                String value = controller.text;
                if (value.isNotEmpty) {
                  updateUserData(field, value);
                }
                Navigator.pop(context);
              },
              child: Text("Сохранить", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editPhoneNumber() async {
    TextEditingController controller = TextEditingController(text: userPhoneNumber.replaceAll(selectedRegion, ""));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color(0xFF111111),
          title: Text("Изменить номер телефона", style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  DropdownButton<String>(
                    dropdownColor: Colors.black,
                    value: selectedRegion,
                    items: regionPrefixes.keys.map((String region) {
                      return DropdownMenuItem<String>(
                        value: regionPrefixes[region]!,
                        child: Text(region, style: TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        selectedRegion = newValue!;
                      });
                    },
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      style: TextStyle(color: Colors.white),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly, // Только цифры
                        LengthLimitingTextInputFormatter(10), // Ограничение на 10 цифр
                      ],
                      decoration: InputDecoration(
                        hintText: 'Введите номер телефона',
                        hintStyle: TextStyle(color: Colors.white),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Отмена", style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                String value = controller.text;
                if (value.isNotEmpty) {
                  updateUserData("phone", value);
                }
                Navigator.pop(context);
              },
              child: Text("Сохранить", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color(0xFF111111),
          title: Text("Удалить аккаунт?", style: TextStyle(color: Colors.white)),
          content: Text(
            "Вы уверены, что хотите удалить свой аккаунт? Это действие необратимо.",
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Отмена", style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                _deleteAccount();
                Navigator.pop(context);
              },
              child: Text("Удалить", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}