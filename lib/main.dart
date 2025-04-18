import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_db_app/model/film_note.dart';
import 'package:flutter_db_app/service/database_helper.dart';
import 'package:flutter_db_app/theme/theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:influxdb_client/api.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
    if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  SharedPreferences preferences = await SharedPreferences.getInstance();
  bool isDarkMode = preferences.getBool("isDarkTheme") ?? false;
  runApp(ChangeNotifierProvider(
    create: (BuildContext context) => ThemeProvider(isDarkMode: isDarkMode),
    child: MainApp(),
  ));

  // await initializeInfluxDBClient(isDarkMode ? 2 : 1);
}

// InfluxDBClient? client;

// Future<void> initializeInfluxDBClient(int mode) async {
//   var token = 'U1PQtJlRAYMUdfAeV_g5DoogDjJ6oOUHBQlO4LX-74w2mnJU2Rwhw8SMW6SGHBlJ1REYJbK9eiOa3PPAYXIp4Q==';
//   var bucket = 'metrics';
//   var org = 'MPT';

//   try {
//     client = InfluxDBClient(
//         url: 'http://10.0.2.2:8086',
//         token: token,
//         org: org,
//         bucket: bucket);

//     var point = Point('mode')
//     .addField('mode', mode)
//     .time(DateTime.now().toUtc());

//     var writeService = client!.getWriteService();
//     await writeService.write(point).then((value) {
//       print('Write completed');
//     }).catchError((exception) {
//       print(exception);
//     });


//     print('все ОК.');
//     client?.close();
//   } catch (e) {
//     print('$e');
    
//   }
//}


class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
        builder: (context, themeProvider, child){
          return MaterialApp(
            theme: themeProvider.getTheme,
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case '/modify':
                  final int? filmId = settings.arguments as int?;
                  return MaterialPageRoute(
                    builder: (_) => ModifyPage(filmId: filmId),
                  );
                case '/home':
                default:
                  return MaterialPageRoute(builder: (_) => ListFilms());
              }
            },
            initialRoute: '/home',
          );
        }
    );
  }
}

class ListFilms extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => _ListFilmsScreenState();
}

class _ListFilmsScreenState extends State<ListFilms> {
  final TextEditingController _controller = TextEditingController();
  DatabaseHelper _databaseHelper = new DatabaseHelper();
  List<FilmNote> _notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    List<FilmNote> notes = await _databaseHelper.getFilms();
    setState(() {
      _notes = notes;
    });
  }


  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text("Home"),
        actions: <Widget>[
          IconButton(
              onPressed: (){
                ThemeProvider themeProvider = Provider.of<ThemeProvider>(
                  context,
                  listen: false,
                );
                themeProvider.swapTheme();
              },
              icon:Icon(Icons.brightness_6)
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
                child: ListView.builder(
                  itemCount: _notes.length,
                  itemBuilder: (context, index) {
                    return _buildItem(_notes[index]);
                  },
                )
            ),
            FloatingActionButton(
                onPressed: () async{
                  await Navigator.pushNamed(context, '/modify');
                  _loadNotes();
                },
                child: Icon(Icons.add))
          ],
        ),
      ),
    );
  }

  Widget _buildItem(FilmNote note) {
    return Card(
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            note.image != null ?
            Image.memory(
              note.image!,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(Icons.image_not_supported),
            )
                : note.imageUrl != null ?
            Image.network(
              note.imageUrl!,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(Icons.image_not_supported),
            )
                : Text("Нет превью"),
            const SizedBox(width: 10.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(note.title),
                  Text(note.genre),
                  Text(note.year),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () async {
                await Navigator.pushNamed(context, '/modify', arguments: note.id);
                _loadNotes();
              },
            ),

            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () async {
                await _databaseHelper.deleteFilm(note.id);
                _loadNotes();

              },
            ),
          ],
        ),
      ),
    );
  }
}

class ModifyPage extends StatefulWidget {
  final int? filmId;

  ModifyPage({Key? key, this.filmId}) : super(key: key);

  @override
  _ModifyPageState createState() => _ModifyPageState();
}

class _ModifyPageState extends State<ModifyPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _genreController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();
  Uint8List? _imageBytes;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    if (widget.filmId != null) {
      _loadFilm(widget.filmId!);
    }
  }

  Future<void> _loadFilm(int id) async {
    final film = await _databaseHelper.getFilmById(id);
    setState(() {
      _titleController.text = film.title;
      _genreController.text = film.genre;
      _yearController.text = film.year;
      _imageBytes = film.image;
      if (film.imageUrl != null) {
        _imageController.text = film.imageUrl!;
      }
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await File(pickedFile.path).readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveFilm() async {
    if (_titleController.text.isEmpty ||
        _genreController.text.isEmpty ||
        _yearController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Заполните все обязательные поля')),
      );
      return;
    }

    final film = FilmNote(
      id: widget.filmId,
      title: _titleController.text,
      genre: _genreController.text,
      year: _yearController.text,
      image: _selectedImage != null ? _imageBytes : _imageBytes,
      imageUrl: _imageController.text.isNotEmpty ? _imageController.text : null,
    );

    if (widget.filmId == null) {
      await _databaseHelper.insertFilm(film);
    } else {
      await _databaseHelper.updateFilm(film);
    }

    Navigator.pop(context);
  }


  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.filmId == null ? 'Добавить' : 'Изменить'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_selectedImage != null)
              Image.file(_selectedImage!, height: 200)
            else if (_imageBytes != null)
              Image.memory(_imageBytes!, height: 200)
            else if (_imageController.text.isNotEmpty)
              Image.network(
                _imageController.text,
                height: 200,
                errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 100),
              ),
            const SizedBox(height: 10),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Название'),
            ),
            TextField(
              controller: _genreController,
              decoration: const InputDecoration(labelText: 'Жанр'),
            ),
            TextField(
              controller: _yearController,
              decoration: const InputDecoration(labelText: 'Год'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _imageController,
              decoration: const InputDecoration(labelText: 'Ссылка на изображение'),
            ),
            const SizedBox(height: 10),
            _selectedImage != null
                ? Image.file(_selectedImage!, height: 150)
                : _imageController.text.isNotEmpty
                ? Image.network(
              _imageController.text,
              height: 150,
              errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
            )
                : Container(
                height: 150,
                color: Colors.grey[300],
                child: const Center(child: Text('Нет изображения'))),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text('Выбрать из галереи'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveFilm,
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}

