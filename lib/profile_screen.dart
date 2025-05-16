import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'boards.dart'; // Подключение файла с BoardsScreen

class ProfileScreen extends StatefulWidget {
  final String userId;

  ProfileScreen({required this.userId});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userName = "Загрузка...";
  String userPhoneNumber = "Загрузка...";
  String userAcctag = "Загрузка...";
  String? userPhotoUrl;
  List<dynamic> userBoards = [];
  bool isLoadingBoards = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchUserBoards();
  }

  Future<void> fetchUserData() async {
    try {
      final response = await http.get(Uri.parse('https://retroispk.ru/profile/${widget.userId}'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          userName = data['user_name'] ?? "Неизвестный пользователь";
          userPhoneNumber = data['user_phone_number'] ?? "Не указан номер телефона";
          userAcctag = data['user_acctag'] ?? "@Неизвестный";
          userPhotoUrl = data['avatar_url'];
        });
      } else {
        setState(() {
          userName = "Ошибка загрузки";
          userPhoneNumber = "Попробуйте позже";
          userAcctag = "@Ошибка";
          userPhotoUrl = null;
        });
      }
    } catch (error) {
      setState(() {
        userName = "Ошибка сети";
        userPhoneNumber = "Нет соединения";
        userAcctag = "@Нет соединения";
        userPhotoUrl = null;
      });
    }
  }

  Future<void> fetchUserBoards() async {
    try {
      final response = await http.get(Uri.parse('https://retroispk.ru/boards/user/${widget.userId}'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          userBoards = data;
          isLoadingBoards = false;
        });
      } else {
        setState(() {
          userBoards = [];
          isLoadingBoards = false;
        });
      }
    } catch (error) {
      setState(() {
        userBoards = [];
        isLoadingBoards = false;
      });
      print('Ошибка загрузки досок: $error');
    }
  }

  void showCreateBoardDialog() {
    final TextEditingController boardNameController = TextEditingController();
    String selectedColor = 'green';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF111111),
          title: Text(
            'Создать доску',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: boardNameController,
                decoration: InputDecoration(
                  labelText: 'Имя доски',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                dropdownColor: Color(0xFF111111),
                value: selectedColor,
                items: [
                  DropdownMenuItem(value: 'green', child: Text('Зеленый', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'red', child: Text('Красный', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'blue', child: Text('Синий', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'black', child: Text('Черный', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'yellow', child: Text('Желтый', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'white', child: Text('Белый', style: TextStyle(color: Colors.white))),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedColor = value ?? 'green';
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Цвет доски',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Отмена', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () async {
                final boardName = boardNameController.text.trim();
                if (boardName.isNotEmpty) {
                  await createBoard(boardName, selectedColor);
                  Navigator.pop(context);
                }
              },
              child: Text('Создать', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> createBoard(String boardName, String boardColor) async {
    final url = 'https://retroispk.ru/boards';
    final body = {
      'board_name': boardName,
      'board_colour': boardColor,
      'board_users': [widget.userId],
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 201) {
        print('Доска успешно создана');
        await createColumns();
      } else {
        print('Ошибка создания доски');
      }
    } catch (error) {
      print('Ошибка: $error');
    }
  }

  Future<void> createColumns() async {
    final url = 'https://retroispk.ru/columns';
    final columnsData = [
      {
        'column_name': 'Факты',
        'column_colour': 'white',
        'column_text': null,
        'board_id': widget.userId,
      },
      {
        'column_name': 'Эмоции',
        'column_colour': 'red',
        'column_text': null,
        'board_id': widget.userId,
      },
      {
        'column_name': 'Преимущества',
        'column_colour': 'yellow',
        'column_text': null,
        'board_id': widget.userId,
      },
      {
        'column_name': 'Критика',
        'column_colour': 'black',
        'column_text': null,
        'board_id': widget.userId,
      },
      {
        'column_name': 'Решение',
        'column_colour': 'green',
        'column_text': null,
        'board_id': widget.userId,
      },
      {
        'column_name': 'Контроль',
        'column_colour': 'blue',
        'column_text': null,
        'board_id': widget.userId,
      }
    ];

    try {
      for (var column in columnsData) {
        final response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(column),
        );

        if (response.statusCode == 201) {
          print('Колонка успешно создана');
        } else {
          print('Ошибка создания колонки');
        }
      }
    } catch (error) {
      print('Ошибка: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Профиль'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Color(0xFF111111),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  backgroundImage: userPhotoUrl != null && userPhotoUrl!.isNotEmpty
                      ? NetworkImage(
                      userPhotoUrl!.startsWith('http')
                          ? userPhotoUrl!
                          : 'https://retroispk.ru$userPhotoUrl')
                      : null,
                ),
              ),
              SizedBox(height: 16),
              Text('Имя', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              Text(userName, style: TextStyle(color: Colors.white)),
              SizedBox(height: 8),
              Text('id пользователя', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              Text(userAcctag, style: TextStyle(color: Colors.white)),
              SizedBox(height: 8),
              Text('Номер телефона', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              Text(userPhoneNumber, style: TextStyle(color: Colors.white)),
              SizedBox(height: 8),
              Center(
                child: ElevatedButton(
                  onPressed: showCreateBoardDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  child: Text('Создать доску'),
                ),
              ),
              SizedBox(height: 16),
              Text('Мои доски', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              isLoadingBoards
                  ? Center(child: CircularProgressIndicator())
                  : userBoards.isEmpty
                  ? Center(child: Text("Нет досок", style: TextStyle(color: Colors.white)))
                  : GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: userBoards.length,
                itemBuilder: (context, index) {
                  final board = userBoards[index];
                  return Card(
                    color: board['board_colour'] == 'green'
                        ? Colors.green
                        : board['board_colour'] == 'red'
                        ? Colors.red
                        : board['board_colour'] == 'white'
                        ? Colors.grey
                        : board['board_colour'] == 'black'
                        ? Color(0xFF4F4F4F)
                        : board['board_colour'] == 'yellow'
                        ? Color(0xFFF4A900)
                        : Colors.blue,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BoardsScreen(
                              boardId: board['board_id'].toString(), // Преобразуем в строку
                              boardName: board['board_name'],
                              userId: widget.userId, // Передача userId
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          board['board_name'],
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}