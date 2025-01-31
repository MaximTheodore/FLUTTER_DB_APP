import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier{
  late ThemeData _selectedTheme;

  ThemeData lightTheme = ThemeData.light().copyWith(
    primaryColor: Colors.orange
  );
  ThemeData darkTheme = ThemeData.dark().copyWith(
    primaryColor: Colors.black
  );

  ThemeProvider({bool? isDarkMode}){
    _selectedTheme = isDarkMode! ? darkTheme : lightTheme;
  }

  Future<void> swapTheme() async{
    SharedPreferences preferences = await SharedPreferences.getInstance();
    if(_selectedTheme == darkTheme){
      _selectedTheme = lightTheme;
      preferences.setBool("isDarkTheme", false);
    } else{
      _selectedTheme = darkTheme;
      preferences.setBool("isDarkTheme", true);  
    }
    notifyListeners();
  }
  ThemeData get getTheme => _selectedTheme;
}