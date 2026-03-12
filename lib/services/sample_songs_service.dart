import '../models/song.dart';
import '../models/score.dart';

/// Servicio que proporciona las canciones de ejemplo.
///
/// Más adelante aquí podrías conectar una API, una base de datos, etc.
/// Por ahora solo devuelve una lista estática para no mezclar datos con la UI.
class SampleSongsService {
  SampleSongsService._();

  static const List<Song> sampleSongs = [
    Song(
      title: 'Mayo a La Virgen de La Antigua',
      type: 'JOTA',
      subtype: 'RELIGIOSAS',
      author: 'Diego Pérez Pezuela',
      lyricsPdfPath: 'https://drive.google.com/file/d/1J7_IboqVB84boJs1VM7_SYi-IGl08LCs/view?usp=drivesdk',
      scores: [Score(instrument: 'DULZAINA')],
    ),
    Song(
      title: 'Guiño al Señorío',
      type: 'SEGUIDILLA',
      subtype: 'SEGUIDILLAS A LOS PUEBLOS',
      author: 'Diego Pérez Pezuela',
      lyricsText: 'Letra de ejemplo para "Guiño al Señorío".\nAquí iría la letra en texto.\nMás adelante también PDF o imagen.',
      scores: [Score(instrument: 'DULZAINA')],
    ),
    Song(
      title: 'Pasacalles De La Plaza',
      type: 'JOTA',
      subtype: 'A LAS FIESTAS',
      author: 'Anónimo',
      lyricsText: 'Letra de ejemplo para "Pasacalles De La Plaza".',
      scores: [
        Score(instrument: 'CUERDA', scorePdfPath: 'https://drive.google.com/file/d/1J7_IboqVB84boJs1VM7_SYi-IGl08LCs/view?usp=drivesdk'),
        Score(instrument: 'DULZAINA'),
      ],
    ),
    Song(
      title: 'Vals del Río',
      type: 'JOTA',
      subtype: 'VARIAS',
      author: 'Anónimo',
      lyricsText: 'Letra de ejemplo del "Vals del Río".',
      scores: [Score(instrument: 'CUERDA', scoreImagePath: 'https://media.istockphoto.com/id/867870340/es/foto/abstracto-fondo-de-texto.jpg?s=612x612&w=is&k=20&c=nKMzbc5elJsbbtY7Teg0nWFaSpJuho1A7cE4idIwX2M=')],
    ),
    Song(
      title: 'Fandango Serrano',
      type: 'JOTA',
      subtype: 'VARIAS',
      author: 'Anónimo',
      lyricsText: 'Letra de ejemplo para "Fandango Serrano".',
      scores: [Score(instrument: 'CUERDA', scoreImagePath: 'https://media.istockphoto.com/id/1361321670/es/vector/borde-abstracto-del-adorno-del-alfabeto-negro-aislado-sobre-fondo-blanco-ilustraci%C3%B3n.jpg?s=612x612&w=0&k=20&c=Io5c4c-7ddt4ZxtHJvdZH43zenvR-iNKPPhRXxDbV1w=')],
    ),
  ];
}
