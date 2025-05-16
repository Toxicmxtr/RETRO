import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/services.dart';
import 'profile_screen.dart';

class BoardsScreen extends StatefulWidget {
  final String boardId;
  final String boardName;
  final String userId;

  const BoardsScreen({
    Key? key,
    required this.boardId,
    required this.boardName,
    required this.userId,
  }) : super(key: key);

  @override
  _BoardsScreenState createState() => _BoardsScreenState();
}

class _BoardsScreenState extends State<BoardsScreen> {
  String? boardCreator; // Теперь переменная может быть null
  bool isCreator = false; // Флаг для отображения кнопки
  String boardColor = 'black';
  List<Map<String, dynamic>> columns = [];
  Map<String, dynamic>? selectedColumn;
  List<String> columnTexts = []; // Хранение текстов как списка строк

  final TextEditingController _newTextController = TextEditingController();
  final TextEditingController _inviteUserController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchBoardData();
    _fetchBoardCreator();
  }

  Future<void> _fetchBoardCreator() async {
    try {
      final response = await http.get(Uri.parse('https://retroispk.ru/boards/${widget.boardId}'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['board_creator'] != null) {
          final String fetchedCreator = data['board_creator'].toString().replaceAll(RegExp(r'[{}"]'), '');

          setState(() {
            boardCreator = fetchedCreator;
            isCreator = boardCreator == widget.userId.toString();
          });
        } else {
          print('Ошибка: board_creator отсутствует в ответе сервера.');
        }
      } else {
        print('Ошибка при загрузке данных: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка сети: $e');
    }
  }

  Future<void> fetchBoardData() async {
    final url = 'https://retroispk.ru/boards/${widget.boardId}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          boardColor = data['board_colour'] ?? 'black';
          columns = List<Map<String, dynamic>>.from(data['columns'] ?? []);
          List<int> boardColumnsOrder = List<int>.from(data['board_columns'] ?? []);

          columns.sort((a, b) {
            int indexA = boardColumnsOrder.indexOf(a['column_id']);
            int indexB = boardColumnsOrder.indexOf(b['column_id']);
            return indexA.compareTo(indexB);
          });

          selectedColumn = columns.isNotEmpty ? columns[0] : null;
          columnTexts = selectedColumn != null && selectedColumn!['column_text'] != null
              ? List<String>.from(json.decode(selectedColumn!['column_text']))
              : [];
        });
      } else {
        print('Ошибка загрузки данных доски: ${response.body}');
      }
    } catch (error) {
      print('Ошибка: $error');
    }
  }



  Future<void> _generateInviteLink() async {
    final url = 'https://retroispk.ru/boards/${widget.boardId}/invite-link';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'inviterId': widget.userId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String inviteLink = data['inviteLink'];

        _shareInviteLink(inviteLink);
      } else {
        print('Ошибка при создании ссылки-приглашения');
      }
    } catch (error) {
      print('Ошибка сети: $error');
    }
  }

  void _shareInviteLink(String inviteLink) {
    Share.share('Присоединяйтесь к доске: $inviteLink');
  }

  Future<void> _respondToInvite(String token, String status) async {
    final url = 'https://retroispk.ru/invites/respond';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'token': token, 'status': status}),
      );

      if (response.statusCode == 200) {
        print('Приглашение $status успешно');
      } else {
        print('Ошибка при обновлении статуса приглашения');
      }
    } catch (error) {
      print('Ошибка сети: $error');
    }
  }

  Future<void> _addNewText() async {
    if (_newTextController.text.trim().isEmpty) return;

    final newText = _newTextController.text.trim();

    // Добавляем новый текст в базу данных
    final url = 'https://retroispk.ru/boards/${widget.boardId}/columns/${selectedColumn!['column_id']}/add';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'newText': newText}),
    );

    if (response.statusCode == 200) {
      setState(() {
        // Добавляем новый текст в список
        columnTexts.add(newText);
      });

      // Задержка в 5 секунд для обновления данных
      await Future.delayed(Duration(seconds: 5), () {
        fetchBoardData();
      });

      _newTextController.clear(); // Очищаем поле для новой записи
    } else {
      print('Ошибка при добавлении текста');
    }
  }

  Future<void> _inviteUserToBoard(String userAcctag, String userId) async {
    if (userAcctag.trim().isEmpty) return;

    final url = 'https://retroispk.ru/boards/${widget.boardId}/invite';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'user_acctag': userAcctag, 'user_id': userId}),
    );

    if (response.statusCode == 200) {
      print('Пользователь успешно приглашен в доску');
    } else {
      print('Ошибка при приглашении пользователя');
    }
    _inviteUserController.clear();
  }

  Future<void> _deleteBoard() async {
    final url = 'https://retroispk.ru/boards/${widget.boardId}/delete';

    try {
      final response = await http.delete(Uri.parse(url));

      if (response.statusCode == 200) {
        // Перенаправляем пользователя в профиль после удаления доски
        Navigator.pop(context); // Закрываем экран текущей доски
        Navigator.pop(context); // Возвращаемся в профиль
      } else {
        print('Ошибка при удалении доски');
      }
    } catch (error) {
      print('Ошибка: $error');
    }
  }

  void showAddColumnDialog(BuildContext context) {
    final TextEditingController _newTextController = TextEditingController();
    final Map<String, String> colorTranslations = {
      'green': 'Зелёный',
      'red': 'Красный',
      'blue': 'Синий',
      'white': 'Белый',
      'black': 'Чёрный',
      'yellow': 'Жёлтый',
    };
    final List<String> availableColors = colorTranslations.keys.toList();
    String selectedColor = 'black';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              backgroundColor: Color(0xFF111111),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Добавить колонку',
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _newTextController,
                    maxLength: 20,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Zа-яА-Я\s]')),
                    ],
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Введите название',
                      hintStyle: TextStyle(color: Colors.white54),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  DropdownButton<String>(
                    dropdownColor: Color(0xFF111111),
                    value: selectedColor,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedColor = newValue;
                        });
                      }
                    },
                    items: availableColors.map<DropdownMenuItem<String>>((String color) {
                      return DropdownMenuItem<String>(
                        value: color,
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              margin: EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: _getColorFromString(color),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Text(colorTranslations[color]!, style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Отмена', style: TextStyle(color: Colors.white)),
                ),
                TextButton(
                  onPressed: () async {
                    if (_newTextController.text.trim().isNotEmpty) {
                      await _addNewColumn(_newTextController.text.trim(), selectedColor);
                      if (mounted) {
                        Navigator.of(context).pop();
                        fetchBoardData(); // Обновление после добавления
                      }
                    }
                  },
                  child: Text('ОК', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addNewColumn(String columnName, String columnColor) async {
    try {
      final response = await http.post(
        Uri.parse('https://retroispk.ru/boards/${widget.boardId}/columns'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'column_name': columnName,
          'column_colour': columnColor,
        }),
      );

      if (response.statusCode == 201) {
        print('Колонка успешно добавлена');
      } else {
        print('Ошибка при добавлении колонки: ${response.body}');
      }
    } catch (e) {
      print('Ошибка соединения: $e');
    }
  }

  void _showDeleteConfir(int columnId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF111111),
          title: Text("Удалить колонку?", style: TextStyle(color: Colors.white)),
          content: Text("Все данные будут потеряны.", style: TextStyle(color: Colors.white)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Отмена", style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                deleteColumn(columnId);
              },
              style: TextButton.styleFrom(backgroundColor: Colors.red),
              child: Text("Удалить", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteColumn(int columnId) async {
    final url = 'https://retroispk.ru/boards/${widget.boardId}/columns/$columnId';
    try {
      final response = await http.delete(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          columns.removeWhere((column) => column['column_id'] == columnId);
          if (columns.isNotEmpty) {
            selectedColumn = columns.last;
          } else {
            selectedColumn = null;
          }
        });
      } else {
        print('Ошибка при удалении: ${response.body}');
      }
    } catch (e) {
      print('Ошибка сети: $e');
    }
  }

  void _showEditColumnDialog(int columnId, String currentName) {
    final TextEditingController _editController = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF111111),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Редактировать колонку',
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          content: TextField(
            controller: _editController,
            maxLength: 20,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Zа-яА-Я\s]')),
            ],
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Введите новое название',
              hintStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Отмена', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () async {
                final newName = _editController.text.trim();
                if (newName.isNotEmpty && newName != currentName) {
                  await _updateColumnName(columnId, newName);
                  Navigator.of(context).pop();
                }
              },
              child: Text('ОК', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateColumnName(int columnId, String newName) async {
    try {
      final response = await http.put(
        Uri.parse('https://retroispk.ru/boards/${widget.boardId}/columns/$columnId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'newName': newName}),
      );

      if (response.statusCode == 200) {
        print('✅ Колонка успешно обновлена');
        await fetchBoardData(); // Перезагрузка данных доски
      } else {
        print('❌ Ошибка при обновлении колонки: ${response.body}');
      }
    } catch (e) {
      print('❌ Ошибка соединения: $e');
    }
  }

  Future<void> _deleteTextFromColumn(String text) async {
    final boardId = widget.boardId;
    final columnId = selectedColumn!['column_id'];

    // Мгновенное удаление из UI
    setState(() {
      columnTexts.remove(text);
    });

    try {
      final response = await http.delete(
        Uri.parse('https://retroispk.ru/boards/$boardId/columns/$columnId/delete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'textToDelete': text}),
      );

      if (response.statusCode != 200) {
        print('Ошибка при удалении записи: ${response.body}');
        // Вернуть текст обратно, если запрос не удался
        setState(() {
          columnTexts.add(text);
        });
      }
    } catch (e) {
      print('Ошибка сети: $e');
      setState(() {
        columnTexts.add(text);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _getColorFromString(boardColor),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          if (isCreator)
            IconButton(
              icon: Icon(Icons.share, color: Colors.white),
              onPressed: () {
                _generateInviteLink();
              },
            ),
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    backgroundColor: Color(0xFF111111),
                    title: Text("Дополнительные действия", style: TextStyle(color: Colors.white)),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCreator)
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _showDeleteConfirmation();
                            },
                            child: Text("Удалить доску", style: TextStyle(color: Colors.white)),
                          ),
                        if (isCreator)
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _showInviteUserDialog();
                            },
                            child: Text("Добавить участника", style: TextStyle(color: Colors.white)),
                          ),
                        if (!isCreator) // Показываем кнопку только для участников
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _showLeaveBoard();
                            },
                            child: Text("Покинуть доску", style: TextStyle(color: Colors.white)),
                          ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            loadAndShowBoardMembersDialog(context);
                          },
                          child: Text("Участники", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
        elevation: 0,
        title: Text(
          'Доска "${widget.boardName}"',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          Container(
            color: Colors.black,
            child: Column(
              children: [
                SizedBox(height: 10),
                Container(
                  height: 50,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: columns.map((column) {
                        bool isSelected = selectedColumn == column;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(100, 40),
                              backgroundColor: isSelected
                                  ? Color(0xFF111111)
                                  : _getColorFromString(column['column_colour'] ?? 'black'),
                              side: BorderSide(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                selectedColumn = column;
                                columnTexts = selectedColumn != null && selectedColumn!['column_text'] != null
                                    ? List<String>.from(json.decode(selectedColumn!['column_text']))
                                    : [];
                              });
                            },
                            child: Text(
                              column['column_name'] ?? 'Без названия',
                              style: TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ),
                        );
                      }).toList()
                        ..add(
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Visibility(
                              visible: isCreator,
                              child: GestureDetector(
                                onTap: () => showAddColumnDialog(context),
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                  child: Icon(
                                    Icons.add,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ),
                  ),
                ),
                if (selectedColumn != null)
                  Expanded(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          child: Container(
                            height: 50,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            color: _getColorFromString(selectedColumn!['column_colour'] ?? 'black'),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      selectedColumn!['column_name'] ?? 'Без названия',
                                      style: TextStyle(color: Colors.white, fontSize: 16),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                if (isCreator)
                                  IconButton(
                                    onPressed: () => _showEditColumnDialog(
                                      selectedColumn!['column_id'],
                                      selectedColumn!['column_name'],
                                    ),
                                    icon: Icon(Icons.edit, color: Colors.white),
                                  ),
                                if (isCreator)
                                  IconButton(
                                    onPressed: () => _showDeleteConfir(selectedColumn!['column_id']),
                                    icon: Icon(Icons.delete, color: Colors.white),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                            itemCount: columnTexts.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                                  color: Color(0xFF111111),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          columnTexts[index],
                                          style: TextStyle(color: Colors.white, fontSize: 16),
                                        ),
                                      ),
                                      if (isCreator)
                                        IconButton(
                                          onPressed: () => _deleteTextFromColumn(columnTexts[index]),
                                          icon: Icon(Icons.delete, color: Colors.red),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              child: Icon(Icons.add, color: Colors.black),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      backgroundColor: Color(0xFF111111),
                      title: Text("Добавить запись", style: TextStyle(color: Colors.white)),
                      content: TextField(
                        controller: _newTextController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Введите текст",
                          hintStyle: TextStyle(color: Colors.grey),
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
                            _addNewText();
                            Navigator.pop(context);
                          },
                          child: Text("ОК", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void loadAndShowBoardMembersDialog(BuildContext context) async {
    try {
      final boardId = widget.boardId;
      if (boardId == null || boardId.isEmpty) {
        print('Невалидный boardId');
        return;
      }

      final members = await _fetchBoardMembers(boardId);
      _showBoardMembersDialog(context, members);
    } catch (e) {
      print('Ошибка при загрузке участников: $e');
    }
  }

  Future<List<dynamic>> _fetchBoardMembers(String boardId) async {
    final url = 'https://retroispk.ru/api/boards/$boardId/members';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Ошибка загрузки: ${response.statusCode}');
    }
  }

  void _showBoardMembersDialog(BuildContext context, List<dynamic> members) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 400,
          height: 500,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFF111111), // Фон окна
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                "Участники",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final user = members[index];
                    final avatarUrl = user['avatar_url'];
                    final userName = user['user_name'];
                    final userAcctag = user['user_acctag'];
                    final userId = user['user_id'];

                    // Приводим оба userId к числовому типу данных, чтобы исключить возможные проблемы с типами
                    int currentUserId = int.tryParse(widget.userId.toString()) ?? -1;
                    int memberUserId = int.tryParse(userId.toString()) ?? -1;

                    // Печать обоих user_id для отладки
                    print('Текущий userId: $currentUserId, Отображаемый userId: $memberUserId');

                    // Проверяем, что userId текущего пользователя не совпадает с userId участника
                    bool isCurrentUser = currentUserId == memberUserId;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white,
                            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                                ? NetworkImage('https://retroispk.ru$avatarUrl')
                                : null,
                            child: avatarUrl == null || avatarUrl.isEmpty
                                ? Icon(Icons.person, color: Colors.grey)
                                : null,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
                                ),
                                Text(
                                  userAcctag,
                                  style: TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          if (!isCurrentUser && isCreator)
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.red),
                              onPressed: () async {
                                final shouldRemove = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: Color(0xFF111111),
                                    title: Text("Исключить пользователя?", style: TextStyle(color: Colors.white)),
                                    content: Text("Вы уверены, что хотите исключить этого пользователя из доски?", style: TextStyle(color: Colors.white)),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: Text("Отмена", style: TextStyle(color: Colors.white)),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: Text("Исключить", style: TextStyle(color: Colors.white)),
                                        style: TextButton.styleFrom(backgroundColor: Colors.red),
                                      ),
                                    ],
                                  ),
                                );
                                if (shouldRemove == true) {
                                  await _kickUserFromBoard(widget.boardId!, userId);
                                  Navigator.pop(context); // Закрываем и перезагружаем диалог
                                  loadAndShowBoardMembersDialog(context);
                                }
                              },
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _kickUserFromBoard(String boardId, int userId) async {
    final url = 'https://retroispk.ru/kickUserFromBoard';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'board_id': boardId, 'user_id': userId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Ошибка при исключении пользователя: ${response.body}');
    }
  }

  void _showLeaveBoard() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color(0xFF111111),
          title: Text("Покинуть доску?", style: TextStyle(color: Colors.white)),
          content: Text(
            "Вы уверены, что хотите покинуть эту доску?",
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Закрываем диалог
              },
              child: Text("Отмена", style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Закрываем диалог
                try {
                  final response = await http.post(
                    Uri.parse('https://retroispk.ru/leaveBoard'),
                    headers: {"Content-Type": "application/json"},
                    body: jsonEncode({
                      "board_id": widget.boardId.toString(),
                      "user_id": widget.userId.toString(),
                    }),
                  );

                  if (response.statusCode == 200) {
                    // Переход на экран профиля с обновлением
                    Navigator.pop(context); // Убираем диалог
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(userId: widget.userId),
                      ),
                    );
                  } else {
                    print("Ошибка при выходе: ${response.body}");
                  }
                } catch (e) {
                  print("Ошибка сети: $e");
                }
              },
              child: Text("Да", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showInviteUserDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color(0xFF111111),
          title: Text(
            "Пригласить участника",
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: _inviteUserController,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Введите тэг пользователя",
              hintStyle: TextStyle(color: Colors.grey),
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
                _inviteUserToBoard(_inviteUserController.text, widget.userId);
                Navigator.pop(context);
              },
              child: Text("Пригласить", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Color _getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'green':
        return Colors.green;
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'white':
        return Colors.grey;
      case 'black':
        return Color(0xFF4F4F4F);
      case 'yellow':
        return Color(0xFFF4A900);
      default:
        return Colors.black;
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color(0xFF111111),
          title: Text("Подтверждение удаления", style: TextStyle(color: Colors.white)),
          content: Text(
            "Вы уверены, что хотите удалить эту доску? Все данные будут потеряны.",
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
                Navigator.pop(context);
                _deleteBoard();
              },
              child: Text("Удалить", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}