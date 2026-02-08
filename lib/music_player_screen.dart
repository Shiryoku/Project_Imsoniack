import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'music_manager.dart';

class MusicPlayerScreen extends StatefulWidget {
  final String title;
  final String image;
  final String file;
  final Color? color;
  final bool isLocal;

  const MusicPlayerScreen({
    super.key,
    required this.title,
    required this.image,
    required this.file,
    this.color,
    this.isLocal = false,
  });

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  final MusicManager _musicManager = MusicManager();
  bool _isLiked = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isLooping = true; // Default to loop for rain sounds?

  @override
  void initState() {
    super.initState();
    _musicManager.addListener(_onMusicStateChanged);
    
    // Listen to Position/Duration
    _musicManager.audioPlayer.onPositionChanged.listen((p) {
       if (mounted) setState(() => _position = p);
    });
    _musicManager.audioPlayer.onDurationChanged.listen((d) {
       if (mounted) setState(() => _duration = d);
    });

    // Sync initial state
    if (_musicManager.audioPlayer.state == PlayerState.playing) {
       // If already playing, grab current pos?
       // Actually streams will update.
    }
  }

  @override
  void dispose() {
    _musicManager.removeListener(_onMusicStateChanged);
    super.dispose();
  }

  void _onMusicStateChanged() {
    if (mounted) setState(() {});
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds"; 
    // Wait, typical music is mm:ss. 
    // If hours > 0, show hh:mm:ss.
    if (d.inHours > 0) return "${d.inHours}:$twoDigitMinutes:$twoDigitSeconds";
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
  
  String _formatTime(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    // Usually standard music player is M:SS or MM:SS
    // Note: Rain sounds might be long, but usually loops are short.
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    // Use Manager data if available, else widget
    final String displayTitle = _musicManager.currentTitle.isNotEmpty ? _musicManager.currentTitle : widget.title;
    final String displayImage = _musicManager.currentImage.isNotEmpty ? _musicManager.currentImage : widget.image;
    
    // Check if image is asset or network
    ImageProvider imageProvider;
    if (displayImage.startsWith('http')) {
      imageProvider = NetworkImage(displayImage);
    } else {
      imageProvider = AssetImage(displayImage);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
            // Network/Battery icons would be system UI, not app bar.
            // Placeholder for "22:00" etc is system status bar.
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Title
            Text(
              displayTitle,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 32),
            
            // Image
            Container(
              height: 320,
              width: 320, // Square aspect
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: imageProvider,
                  fit: BoxFit.cover,
                ),
                boxShadow: const [
                  BoxShadow(
                     color: Colors.black12,
                     blurRadius: 15,
                     offset: Offset(0, 10),
                  )
                ],
              ),
            ),
            const Spacer(),
            
            // Controls Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous, size: 32),
                  onPressed: () {
                     // Skip Previous
                     _musicManager.playPrevious();
                  }, 
                ),
                IconButton(
                  icon: Icon(Icons.loop, size: 28, color: _isLooping ? Colors.black : Colors.grey),
                  onPressed: () {
                     setState(() => _isLooping = !_isLooping);
                     _musicManager.audioPlayer.setReleaseMode(
                        _isLooping ? ReleaseMode.loop : ReleaseMode.stop
                     );
                  },
                ),
                
                // Play Button (Circle)
                GestureDetector(
                  onTap: () {
                     _musicManager.playMusic(
                         widget.file, 
                         widget.title, 
                         widget.image, 
                         widget.color ?? Colors.grey,
                         isLocal: widget.isLocal,
                     ); 
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: Icon(
                      _musicManager.isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 32,
                      color: Colors.black,
                    ),
                  ),
                ),

                IconButton(
                  icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border, size: 28),
                  color: _isLiked ? Colors.red : Colors.black,
                  onPressed: () {
                    setState(() => _isLiked = !_isLiked);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next, size: 32),
                  onPressed: () {
                     // Skip Next
                     _musicManager.playNext();
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 24),

            // Slider
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbColor: Colors.black,
                activeTrackColor: Colors.black,
                inactiveTrackColor: Colors.grey[300],
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              ),
              child: Slider(
                value: _position.inSeconds.toDouble().clamp(0, _duration.inSeconds.toDouble()),
                max: _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1,
                onChanged: (val) {
                   _musicManager.audioPlayer.seek(Duration(seconds: val.toInt()));
                },
              ),
            ),
            
            // Time Labels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(_formatTime(_position), style: const TextStyle(fontSize: 12)),
                   Text(_formatTime(_duration), style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
