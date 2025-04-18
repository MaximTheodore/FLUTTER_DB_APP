import 'package:flutter/material.dart';
import 'package:flutter_listview_note/model/NoteItem.dart';

class NoteItemProvider extends ChangeNotifier {
  final List<NoteItem> _simpleNotes = [];

  List<NoteItem> getNoteItems(){
    return _simpleNotes;
  }
  NoteItem getNoteItem(int index){
    return _simpleNotes[index];
  }

  void addNoteItem(String name){
    NoteItem noteItem = NoteItem(name);
    _simpleNotes.add(noteItem);
    notifyListeners();
  }
  void updateNoteItem(int index){
    _simpleNotes.insert(index, _simpleNotes[index]);
    notifyListeners();
  }
  
  void removeNoteItem(int index){
    _simpleNotes.removeAt(index);
    notifyListeners();
  }
  

}