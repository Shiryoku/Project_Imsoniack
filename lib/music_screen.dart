import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'subscription_manager.dart';
import 'subscription_screen.dart';
import 'music_manager.dart';
import 'music_player_screen.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  final MusicManager _musicManager = MusicManager();
  
  // Categories Data
  final List<Map<String, dynamic>> _categories = [
    {
      'title': 'Custom',
      'image': 'https://placeholder.com/custom',
      'gradient': '0xFF607D8B', // Blue Grey
      'songs': <Map<String, dynamic>>[], // Empty initially
    },
    {
      'title': 'Rain Sounds',
      'image': 'assets/images/rain_cover.jpg', 
      'gradient': '0xFF4A6572', 
      'file': 'rain/rain.mp3', 
    },
    {
      'title': 'Brown Noise',
      'title': 'Brown Noise',
      'image': 'assets/images/brown_noise_cover.jpg',
      'gradient': '0xFF5D4037',
      'file': 'brown_noise/brown_noise.mp3', // Single track
    },
    {
      'title': 'White Noise',
      'image': 'assets/images/white_noise_cover.jpg',
      'gradient': '0xFF90A4AE',
      'file': 'white_noise/white_noise.mp3', // Single track
    },
    {
      'title': 'Lo-Fi',
      'image': 'assets/images/lofi_cover.jpg',
      'gradient': '0xFF7B1FA2',
      'songs': [
         {'title': 'Chill Vibes', 'file': 'lofi/lofi1.mp3'},
         {'title': 'Study Beats', 'file': 'lofi/lofi2.mp3'},
         {'title': 'Night Walk', 'file': 'lofi/lofi3.mp3'},
         {'title': 'Relaxing flow', 'file': 'lofi/lofi4.mp3'},
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    // Listen to manager changes to update UI (icons etc)
    _musicManager.addListener(_onMusicStateChanged);
    SubscriptionManager().addListener(_onSubscriptionChanged);
  }

  @override
  void dispose() {
    _musicManager.removeListener(_onMusicStateChanged);
    SubscriptionManager().removeListener(_onSubscriptionChanged);
    super.dispose();
  }

  void _onMusicStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onSubscriptionChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _pickSong() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null) {
      PlatformFile file = result.files.first;
      
      setState(() {
        final customCategory = _categories.firstWhere((cat) => cat['title'] == 'Custom');
        (customCategory['songs'] as List).add({
          'title': file.name,
          'file': file.path!,
          'isLocal': true,
        });
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Added ${file.name} to Custom list")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Text(
            'Music',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              return _buildCategoryCard(category);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final bool isPlaylist = category.containsKey('songs');
    final String title = category['title'];
    final String image = category['image'];
    final Color bgColor = Color(int.parse(category['gradient']!));
    
    // Lock Logic
    final bool isFree = title == 'Rain Sounds';
    final bool isUnlocked = SubscriptionManager().isSubscribed || isFree;

    
    ImageProvider? bgImage;
    if (image.startsWith('http')) {
       bgImage = NetworkImage(image);
    } else if (image.startsWith('assets')) {
       bgImage = AssetImage(image);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        image: bgImage != null ? DecorationImage(
          image: bgImage,
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black.withAlpha(100), BlendMode.darken),
        ) : null,
      ),
      child: !isUnlocked 
        ? ListTile( // Locked State
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black, blurRadius: 2)],
              ),
            ),
            trailing: const Icon(Icons.lock, color: Colors.white, size: 30),
            onTap: () {
               Navigator.push(
                 context,
                 MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
               );
            },
          )
        : isPlaylist // Unlocked State (Normal logic)
          ? Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              collapsedIconColor: Colors.white,
              iconColor: Colors.white,
              title: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                ),
              ),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(50),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    children: [
                        if (title == 'Custom')
                             Padding(
                               padding: const EdgeInsets.all(8.0),
                               child: ElevatedButton.icon(
                                 onPressed: _pickSong,
                                 icon: const Icon(Icons.add),
                                 label: const Text("Add Song"),
                                 style: ElevatedButton.styleFrom(
                                   backgroundColor: Colors.white,
                                   foregroundColor: bgColor,
                                 ),
                               ),
                             ),
                        ...(category['songs'] as List).asMap().entries.map<Widget>((entry) {
                          final index = entry.key;
                          final song = entry.value;
                          final isPlayingThis = _musicManager.currentlyPlayingFile == song['file'] && _musicManager.isPlaying;
                          final isLocal = song.containsKey('isLocal') && song['isLocal'] == true;
                          
                          // Prepare playlist for this category
                          // We clone the list and ensure every item has the category image/color if missing
                          final List<Map<String, dynamic>> playlist = (category['songs'] as List).map<Map<String, dynamic>>((s) {
                             return {
                               'title': s['title'],
                               'file': s['file'],
                               'image': s['image'] ?? image, // Use category image if song doesn't have one
                               'color': s['color'] ?? bgColor,
                               'isLocal': s.containsKey('isLocal') && s['isLocal'] == true,
                             };
                          }).toList();

                          return ListTile(
                            title: Text(
                              song['title'],
                              style: const TextStyle(color: Colors.white),
                            ),
                            trailing: Icon(
                              isPlayingThis ? Icons.graphic_eq : Icons.play_circle_outline, 
                              color: Colors.white,
                              size: 24,
                            ),
                            // Handle playing
                            onTap: () {
                                _musicManager.playMusic(
                                    song['file'], 
                                    song['title'], 
                                    image, 
                                    bgColor, 
                                    isLocal: isLocal,
                                    playlist: playlist,
                                    index: index,
                                );
                                Navigator.push(context, MaterialPageRoute(builder: (_) => MusicPlayerScreen(
                                  title: song['title'],
                                  image: image,
                                  file: song['file'],
                                  color: bgColor,
                                  isLocal: isLocal,
                                )));
                            },
                          );
                        }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          )
        : ListTile( // Single Track
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black, blurRadius: 2)],
              ),
            ),
            trailing: Icon(
              (_musicManager.currentlyPlayingFile == category['file'] && _musicManager.isPlaying) 
                  ? Icons.graphic_eq 
                  : Icons.play_circle_fill,
              color: Colors.white,
              size: 40,
            ),
            onTap: () {
                _musicManager.playMusic(category['file'], title, image, bgColor);
                Navigator.push(context, MaterialPageRoute(builder: (_) => MusicPlayerScreen(
                  title: title,
                  image: image,
                  file: category['file'],
                  color: bgColor,
                )));
            },
          ),
    );
  }
}
