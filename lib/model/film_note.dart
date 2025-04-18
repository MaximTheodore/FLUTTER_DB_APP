import 'dart:typed_data';
import 'dart:ui';

class FilmNote {
  final int? id;
  final Uint8List? image;
  final String? imageUrl;
  final String title;
  final String genre;
  final String year;

  FilmNote({
    this.id, 
    required this.image,
    required this.imageUrl,
    required this.title, 
    required this.genre, 
    required this.year
  });
  Map<String, dynamic> toMap(){
    return {
      'id': id,
      'title': title,
      'image': image,
      'imageUrl': imageUrl,
      'genre': genre,
      'year': year,
    };
  }
  factory FilmNote.fromMap(Map<String, dynamic> map) {
    return FilmNote(
      id: map['id'],
      title: map['title'],
      genre: map['genre'],
      year: map['year'],
      image: map['image'],
      imageUrl: map['imageUrl'],
    );
  }
  @override
  String toString(){
    return 'FilmNote{id: $id, image: $image, title: $title, genre: $genre, year: $year}';
  }
  
}