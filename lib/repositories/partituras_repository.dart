import '../models/song.dart';
import 'songs_repository.dart';

abstract class PartiturasRepository {
  Future<List<Song>> getSongs();
  Future<List<String>> getSongTypes();
  Future<List<String>> getInstruments();
  Future<DateTime?> getSongsLastSyncAt();
  Future<List<String>> getPartiturasSubtypesByInstrument(String instrumentName);
  Future<int> syncSongsCacheFromRemote();
}

class SongsPartiturasRepository implements PartiturasRepository {
  SongsPartiturasRepository({SongsRepository? songsRepository})
    : _songsRepository = songsRepository ?? SongsRepository();

  final SongsRepository _songsRepository;

  @override
  Future<List<Song>> getSongs() => _songsRepository.getSongs();

  @override
  Future<List<String>> getSongTypes() => _songsRepository.getSongTypes();

  @override
  Future<List<String>> getInstruments() => _songsRepository.getInstruments();

  @override
  Future<DateTime?> getSongsLastSyncAt() => _songsRepository.getSongsLastSyncAt();

  @override
  Future<List<String>> getPartiturasSubtypesByInstrument(String instrumentName) =>
      _songsRepository.getPartiturasSubtypesByInstrument(instrumentName);

  @override
  Future<int> syncSongsCacheFromRemote() =>
      _songsRepository.syncSongsCacheFromRemote();
}
