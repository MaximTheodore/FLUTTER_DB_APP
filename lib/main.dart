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

  

  @override
  Widget build(BuildContext context) {
    var noteList = context.watch<NoteItemProvider>();
    return Scaffold( 
      appBar: AppBar(
        title: Text(widget.index == -1 ? 'Add' : 'Edit'),
      ),
      body: Container(
        alignment: Alignment.center,
        margin: EdgeInsets.all(50),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              
              controller: _controller,
              decoration: InputDecoration(
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
                contentPadding: EdgeInsets.only(
                  top: 10,
                  left: 10,
                  right: 10
                  ),
                hintText: "Введите заметку"
              ),
            ),
            ElevatedButton(
              onPressed: (){
                setState(() {
                  if (widget.index == -1 && _controller.text.isNotEmpty) {
                    noteList.addNoteItem(_controller.text);
                  } else {
                    noteList.getNoteItem(widget.index).name = _controller.text;
                  }
                });
                Navigator.pushNamed(context, '/home');
              }, 
              child: Text(widget.index == -1 ? 'Добавить' : 'Изменить')),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: (){
                  Navigator.pushNamed(context, '/home');
                }, 
                child: Text("Назад"))
          ],

          
        ),
      ),
    );
  }
}

