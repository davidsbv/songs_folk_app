import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:songs_folk_app/models/score.dart';
import 'package:songs_folk_app/models/song.dart';
import 'package:songs_folk_app/screens/song_detail_screen.dart';

void main() {
  testWidgets('renderiza letra y bloque de partituras', (tester) async {
    const song = Song(
      title: 'Mi cancion',
      author: 'Autor',
      type: 'JOTA',
      subtype: 'TRADICIONAL',
      lyricsText: 'Texto de prueba',
      scores: [Score(instrument: 'CUERDA')],
    );
    await tester.pumpWidget(
      const MaterialApp(home: SongDetailScreen(song: song)),
    );
    expect(find.text('Letra'), findsOneWidget);
    expect(find.text('Texto de prueba'), findsOneWidget);
    expect(find.text('Partituras y tablaturas'), findsOneWidget);
  });

  testWidgets('muestra estado sin recursos cuando faltan', (tester) async {
    const song = Song(
      title: 'Sin recursos',
      author: 'Anonimo',
      type: 'JOTA',
      subtype: 'TRADICIONAL',
      scores: [Score(instrument: 'DULZAINA')],
    );
    await tester.pumpWidget(
      const MaterialApp(home: SongDetailScreen(song: song)),
    );
    expect(find.text('Sin letra cargada.'), findsOneWidget);
    expect(find.text('Sin partitura cargada.'), findsOneWidget);
    expect(find.text('Sin tablatura cargada.'), findsOneWidget);
  });
}
