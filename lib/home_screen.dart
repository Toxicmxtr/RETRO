import 'package:flutter/material.dart';
import 'package:untitled/login_screen.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart'; // Импорт для работы с изображениями
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

class HomeScreen extends StatefulWidget {
  final String userId;

  HomeScreen({required this.userId});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription? _sub;
  String userName = "Загрузка...";
  String userPhoneNumber = "Загрузка...";
  List<dynamic> posts = [];
  Timer? _timer;
  File? _selectedImage; // Для хранения выбранного изображения
  String? userPhotoUrl;
  Set<String> viewedPostIds = Set<String>();
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchPosts();
    _handleIncomingLinks();
    _timer = Timer.periodic(Duration(seconds: 30), (timer) {
      fetchUserData();
      fetchPosts();
    });
  }

  void _handleIncomingLinks() {
    _appLinks = AppLinks();

    // Получаем ссылку, с которой открыли приложение
    _appLinks.getInitialAppLink().then((Uri? uri) {
      if (uri != null) {
        _processUri(uri);
      }
    }).catchError((err) {
      print("Ошибка получения initial link: $err");
    });

    // Подписка на входящие ссылки
    _linkSubscription = _appLinks.uriLinkStream.listen((Uri uri) {
      _processUri(uri);
    }, onError: (err) {
      print("Ошибка обработки входящей ссылки: $err");
    });
  }

  void _processUri(Uri uri) {
    if (uri.toString().contains("https://retroispk.ru/invite/")) {
      List<String> segments = uri.pathSegments;
      if (segments.isNotEmpty && segments[0] == "invite") {
        String boardId = segments[1];
        _showInviteDialog(boardId);
      }
    }
  }

  Future<void> fetchUserData() async {
    try {
      final response = await http.get(Uri.parse('https://retroispk.ru/home/${widget.userId}'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          userName = data['user_name'] ?? "Неизвестный пользователь";
          userPhoneNumber = data['user_phone_number'] ?? "Не указан номер телефона";
          userPhotoUrl = data['avatar_url'];
        });
      } else {
        setState(() {
          userName = "Ошибка загрузки";
          userPhoneNumber = "Попробуйте позже";
        });
      }
    } catch (error) {
      setState(() {
        userName = "Ошибка сети";
        userPhoneNumber = "Нет соединения";
      });
    }
  }

  Future<void> fetchPosts() async {
    try {
      final response = await http.get(Uri.parse('https://retroispk.ru/posts'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          setState(() {
            posts = data;
          });
        } else {
          throw FormatException("Неверная структура данных");
        }
      } else {
        throw Exception("Ошибка ответа от сервера: ${response.statusCode}");
      }
    } catch (error) {
      setState(() {
        posts = [];
      });
      print('Ошибка загрузки постов: $error');
    }
  }

  void _showInviteDialog(String boardId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Приглашение в доску"),
          content: Text("Принять приглашение в доску с ID: $boardId?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Отмена"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: добавить логику принятия приглашения
              },
              child: Text("Принять"),
            ),
          ],
        );
      },
    );
  }

  Future<void> incrementPostViews(String postId) async {
    if (viewedPostIds.contains(postId)) {
      print("Пост с ID $postId уже был просмотрен, пропускаем обновление просмотров.");
      return;  // Если пост уже был просмотрен, не увеличиваем просмотры
    }

    try {
      final response = await http.patch(
        Uri.parse('https://retroispk.ru/posts/$postId/views'),
      );

      print("Request sent to increment views for post ID: $postId");
      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        setState(() {
          viewedPostIds.add(postId);  // Добавляем ID поста в список просмотренных
        });
        fetchPosts();  // После увеличения просмотров обновляем список постов
        print("Views incremented successfully for post ID: $postId");
      } else {
        print("Error: Server responded with status code ${response.statusCode}");
      }
    } catch (error) {
      print("Error incrementing post views: $error");
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _sub?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });
    }
  }

  String formatDateAndTime(String date, String time) {
    try {
      DateTime dateTime = DateFormat('yyyy-MM-dd').parse(date).toLocal();
      String formattedDate = DateFormat('yyyy-MM-dd').format(dateTime);
      String formattedTime = time; // Предполагаем, что время уже в правильном формате
      return '$formattedDate $formattedTime';
    } catch (e) {
      return "Ошибка формата времени";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ретр0',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.black, // Цвет текста
          ),
        ),
        backgroundColor: Colors.white, // Цвет AppBar
        elevation: 0, // Убираем тень
        flexibleSpace: null, // Убираем градиент и закругления
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: Icon(Icons.menu, color: Colors.black), // Цвет иконки
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        centerTitle: true, // Центрируем текст
      ),
      drawer: _buildDrawer(),
      body: posts.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: EdgeInsets.all(8),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          var post = posts[index];
          return VisibilityDetector(
            key: Key('post-${post['post_id']}'),
            onVisibilityChanged: (visibilityInfo) {
              // Условие: пост виден более чем на 50%
              if (visibilityInfo.visibleFraction > 0.5) {
                // Когда пост виден, увеличиваем количество просмотров
                incrementPostViews(post['post_id'].toString());
              }
            },
            child: GestureDetector(
              onTap: () => incrementPostViews(post['post_id'].toString()),
              child: Card(
                color: Color(0xFF171717),
                margin: EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white,
                            backgroundImage: post['avatar_url'] != null
                                ? NetworkImage('https://retroispk.ru${post['avatar_url']}')
                                : null,
                          ),
                          SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post['user_name'] ?? "Неизвестный пользователь",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${post['user_acctag'] ?? "unknown"}',
                                style: TextStyle(color: Colors.white54, fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      if (post['post_picture'] != null && post['post_picture'].isNotEmpty)
                        Image.network(
                          '${post['post_picture']}',
                          fit: BoxFit.cover,
                        ),
                      SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xFF1B1B1B),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: MarkdownBody(
                          data: post['post_text'] ?? "",
                          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            formatDateAndTime(post['post_date'], post['post_time']),
                            style: TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          Row(
                            children: [
                              Icon(Icons.remove_red_eye),
                              SizedBox(width: 3),
                              Text(post['post_views'].toString()), // Преобразование числа в строку
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddPostDialog(context);
        },
        child: Icon(Icons.add),
        backgroundColor: Color(0xFF414141), // Цвет фона кнопки
        foregroundColor: Colors.white, // Цвет иконки (белый)
      ),
      backgroundColor: Colors.black, // Цвет фона всего приложения (черный)
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: Color(0xFF111111), // Фон выезжающего меню
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: Text(userName, style: TextStyle(color: Colors.white)), // Цвет текста
              accountEmail: Text(userPhoneNumber, style: TextStyle(color: Colors.white)), // Цвет текста
              currentAccountPicture: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                backgroundImage: userPhotoUrl != null && userPhotoUrl!.isNotEmpty
                    ? NetworkImage('https://retroispk.ru$userPhotoUrl')
                    : null,
              ),
              decoration: BoxDecoration(
                color: Color(0xFF414141), // Цвет фона UserAccountsDrawerHeader
              ),
            ),
            ListTile(
              title: Text('Профиль', style: TextStyle(color: Colors.white)), // Цвет текста
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen(userId: widget.userId)),
                );
              },
            ),
            ListTile(
              title: Text('Настройки', style: TextStyle(color: Colors.white)), // Цвет текста
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsScreen(userId: widget.userId)),
                );
              },
            ),
            ListTile(
              title: Text('Выход', style: TextStyle(color: Colors.white)), // Цвет текста
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }


  void _showAddPostDialog(BuildContext context) {
    TextEditingController postController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Color(0xFF111111), // Цвет фона окна (непрозрачный черный)
          child: Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Новый пост',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextField(
                  controller: postController,
                  style: TextStyle(color: Colors.white),
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Введите текст поста...',
                    hintStyle: TextStyle(color: Colors.white60),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: Icon(Icons.photo, color: Colors.white), // Белая иконка
                      label: Text('Выбрать фото', style: TextStyle(color: Colors.white)), // Белый текст
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent, // Сделать кнопку с прозрачным фоном
                      ),
                    ),
                    if (_selectedImage != null)
                      Text('Фото выбрано', style: TextStyle(color: Colors.green)),
                  ],
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, // Белый фон
                  ),
                  onPressed: () {
                    _createPost(postController.text);
                    Navigator.pop(context);
                    _selectedImage = null;
                  },
                  child: Text(
                    'Создать',
                    style: TextStyle(color: Colors.black), // Черный текст
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String?> uploadPostImage(File imageFile) async {
    try {
      String mimeType = 'application/octet-stream';  // Значение по умолчанию
      if (imageFile.path.endsWith('.jpg') || imageFile.path.endsWith('.jpeg')) {
        mimeType = 'image/jpeg';
      } else if (imageFile.path.endsWith('.png')) {
        mimeType = 'image/png';
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://retroispk.ru/upload-post-picture'),
      );

      /// Добавление файла в запрос с правильным MIME-типом
      var multipartFile = await http.MultipartFile.fromPath(
        'post_picture',  // Параметр, который ожидает сервер
        imageFile.path,
        contentType: MediaType.parse(mimeType),  // Указываем MIME-тип
      );

      // Добавление multipartFile в запрос
      request.files.add(multipartFile);


      var response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final data = json.decode(responseData);
        return data['picture_url'];  // Возвращаем URL изображения
      } else {
        print('Ошибка загрузки изображения');
        return null;
      }
    } catch (error) {
      print("Ошибка сети: $error");
      return null;
    }
  }

  Future<void> _createPost(String text) async {
    try {
      // Получаем текущее время и дату
      DateTime now = DateTime.now().toLocal();
      String currentDate = DateFormat('yyyy-MM-dd').format(now);
      String currentTime = DateFormat('HH:mm:ss').format(now);

      String? imageUrl;

      if (_selectedImage != null) {
        imageUrl = await uploadPostImage(_selectedImage!);
        if (imageUrl == null) {
          print('Ошибка при загрузке изображения');
          return;
        }
      }

      // Проверяем, что хотя бы одно поле заполнено
      if (text.trim().isEmpty && imageUrl == null) {
        print('Ошибка: текст и изображение не могут быть пустыми одновременно');
        return;
      }

      final response = await http.post(
        Uri.parse('https://retroispk.ru/add_posts'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.userId,
          'user_name': userName,
          'post_text': text.isEmpty ? null : text,
          'post_date': currentDate,
          'post_time': currentTime,
          'post_picture': imageUrl,
        }),
      );

      if (response.statusCode == 201) {
        print('Пост успешно добавлен');
        fetchPosts();
        setState(() {
          _selectedImage = null;
        });
      } else {
        print('Ошибка при создании поста. Статус: ${response.statusCode}');
      }
    } catch (error) {
      print('Ошибка при создании поста: $error');
    }
  }
}