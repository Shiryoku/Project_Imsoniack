import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:audio_session/audio_session.dart';

class MusicManager with ChangeNotifier {
  static final MusicManager _instance = MusicManager._internal();
  factory MusicManager() => _instance;

  final AudioPlayer _audioPlayer = AudioPlayer();
  
  String? _currentlyPlayingFile;
  bool _isPlaying = false;
  
  // Track Info
  String _currentTitle = '';
  String _currentImage = ''; 
  Color _currentColor = Colors.grey;
  bool _isLocalTrack = false;

  // Playlist Info
  List<Map<String, dynamic>> _playlist = [];
  int _currentIndex = -1;

  // Getters
  bool get isPlaying => _isPlaying;
  String? get currentlyPlayingFile => _currentlyPlayingFile;
  String get currentTitle => _currentTitle;
  String get currentImage => _currentImage;
  Color get currentColor => _currentColor;
  AudioPlayer get audioPlayer => _audioPlayer;
  bool get hasNext => _playlist.isNotEmpty && _currentIndex < _playlist.length - 1;
  bool get hasPrevious => _playlist.isNotEmpty && _currentIndex > 0;

  MusicManager._internal() {
    _initAudioSession();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      notifyListeners();
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      _isPlaying = false;
      // Auto-play next if available?
      // Optional: if (hasNext) playNext();
      notifyListeners();
    });
  }

  Future<void> playMusic(String fileName, String title, String imageURL, Color color, {bool isLocal = false, List<Map<String, dynamic>>? playlist, int? index}) async {
    bool isNewTrack = _currentlyPlayingFile != fileName;

    if (isNewTrack) {
      await _audioPlayer.stop();
      if (isLocal) {
        await _audioPlayer.play(DeviceFileSource(fileName));
      } else {
        await _audioPlayer.play(AssetSource('audio/$fileName'));
      }
      
      _currentlyPlayingFile = fileName;
      _currentTitle = title;
      _currentImage = imageURL;
      _currentColor = color;
      _isLocalTrack = isLocal;
      
      // Update Playlist Context if provided
      if (playlist != null) {
        _playlist = playlist;
        _currentIndex = index ?? 0;
      } else if (index == null) {
         // If no playlist provided, clear it (single track mode)
         _playlist = [];
         _currentIndex = -1;
      }
    } else {
      if (!_isPlaying) {
        await _audioPlayer.resume();
      } else {
        await _audioPlayer.pause();
      }
    }
    notifyListeners();
  }
  
  Future<void> playNext() async {
    if (hasNext) {
      _currentIndex++;
      final nextSong = _playlist[_currentIndex];
      // Note: We need to know if the next song isLocal or not and its image/color. 
      // The playlist data structure from music_screen needs to be consistent.
      // Assuming playlist items have: title, file, image, color (or inherit image/color from category?)
      // Wait, the playlist in MusicScreen only had title/file.
      // We need to pass the full context.
      
      // For now, let's assume we pass enough data or reuse current image/color?
      // The `songs` map in `MusicScreen` only has title and file. 
      // We should probably pass image/color in the playlist item or reuse current if it's the same album.
      
      String image = nextSong['image'] ?? _currentImage; 
      Color color = nextSong['color'] ?? _currentColor; // Reuse if not specific
      bool isLocal = nextSong['isLocal'] ?? false;
      
      await playMusic(nextSong['file'], nextSong['title'], image, color, isLocal: isLocal, playlist: _playlist, index: _currentIndex);
    }
  }

  Future<void> playPrevious() async {
    if (hasPrevious) {
      _currentIndex--;
      final prevSong = _playlist[_currentIndex];
      String image = prevSong['image'] ?? _currentImage;
      Color color = prevSong['color'] ?? _currentColor;
      bool isLocal = prevSong['isLocal'] ?? false;
      
      await playMusic(prevSong['file'], prevSong['title'], image, color, isLocal: isLocal, playlist: _playlist, index: _currentIndex);
    } else {
      // Seek to start
      await _audioPlayer.seek(Duration.zero);
    }
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    _currentlyPlayingFile = null;
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }
}
