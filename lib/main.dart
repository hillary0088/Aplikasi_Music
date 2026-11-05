
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';

import 'song.dart';
import 'home_screen.dart';
import 'profile.dart';

void main() {
  runApp(const MusicPlayerApp());
}

class MusicPlayerApp extends StatelessWidget {
  const MusicPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HYtune',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<Song> songs = [];
  List<Song> favoriteSongs = [];
  List<Song> currentPlaylist = [];

  final TextEditingController controller = TextEditingController();
  final AudioPlayer player = AudioPlayer();

  Song? currentSong;

  int currentIndex = 0;
  int selectedTabIndex = 0;

  bool isPlaying = false;
  bool isLoading = false;
  bool isDarkMode = false;

  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;

  Color get backgroundColor => isDarkMode
      ? const Color(0xFF241824)
      : const Color(0xFFFFC0D9);

  Color get cardColor => isDarkMode
      ? const Color(0xFF493044)
      : const Color(0xFFFFD6E5);

  Color get selectedColor => isDarkMode
      ? const Color(0xFF70415D)
      : const Color(0xFFFF8FBA);

  Color get textColor => isDarkMode
      ? const Color(0xFFFFD6E5)
      : const Color(0xFF9C2858);

  Color get secondaryTextColor => isDarkMode
      ? const Color(0xFFE5AFC9)
      : const Color(0xFFB34D79);

  final Color pinkColor = const Color(0xFFE84393);

  @override
  void initState() {
    super.initState();

    player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          isPlaying = state == PlayerState.playing;
        });
      }
    });

    player.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          isPlaying = false;
          currentPosition = totalDuration;
        });
      }
    });

    player.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          currentPosition = position;
        });
      }
    });

    player.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          totalDuration = duration;
        });
      }
    });

    loadHits2026();
  }

  // Mengambil daftar lagu Hits 2026
  Future<void> loadHits2026() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://itunes.apple.com/id/rss/topsongs/limit=25/json',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final entries = data['feed']['entry'] as List;

        List<String> ids = [];

        for (var entry in entries) {
          ids.add(entry['id']['attributes']['im:id'].toString());
        }

        final lookupResponse = await http.get(
          Uri.parse(
            'https://itunes.apple.com/lookup?id=${ids.join(',')}&entity=song&country=id',
          ),
        );

        if (lookupResponse.statusCode == 200) {
          final lookupData = jsonDecode(lookupResponse.body);

          List<Song> loadedSongs = [];

          for (var item in lookupData['results']) {
            if (item['kind'] == 'song') {
              loadedSongs.add(Song.fromJson(item));
            }
          }

          if (mounted) {
            setState(() {
              songs = loadedSongs;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengambil daftar lagu'),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Mencari lagu
  Future<void> carilagu() async {
    String keyword = controller.text.trim();

    if (keyword.isEmpty) {
      loadHits2026();
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://itunes.apple.com/search?term=${Uri.encodeComponent(keyword)}&limit=25&entity=song&country=id',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List<Song> searchResults = [];

        for (var item in data['results']) {
          searchResults.add(Song.fromJson(item));
        }

        if (mounted) {
          setState(() {
            songs = searchResults;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pencarian lagu gagal'),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Memutar lagu tanpa langsung membuka halaman Player
  Future<void> playSong(
      Song song, {
        List<Song>? playlist,
      }) async {
    if (song.previewUrl == null || song.previewUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preview lagu tidak tersedia'),
        ),
      );
      return;
    }

    try {
      if (currentSong?.trackId == song.trackId) {
        if (isPlaying) {
          await player.pause();
        } else if (player.state == PlayerState.completed) {
          await player.seek(Duration.zero);
          await player.play(UrlSource(song.previewUrl!));
        } else {
          await player.resume();
        }
      } else {
        List<Song> selectedPlaylist = playlist ?? songs;

        int index = selectedPlaylist.indexWhere(
              (item) => item.trackId == song.trackId,
        );

        await player.stop();

        setState(() {
          currentSong = song;
          currentPlaylist = selectedPlaylist;
          currentIndex = index >= 0 ? index : 0;

          isPlaying = true;
          currentPosition = Duration.zero;
          totalDuration = Duration.zero;
        });

        await player.play(UrlSource(song.previewUrl!));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isPlaying = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak dapat memutar lagu'),
          ),
        );
      }
    }
  }

  // Lagu berikutnya
  Future<void> nextSong() async {
    if (currentPlaylist.isEmpty) return;

    int nextIndex = (currentIndex + 1) % currentPlaylist.length;

    await playSong(
      currentPlaylist[nextIndex],
      playlist: currentPlaylist,
    );
  }

  // Lagu sebelumnya
  Future<void> previousSong() async {
    if (currentPlaylist.isEmpty) return;

    int previousIndex =
        (currentIndex - 1 + currentPlaylist.length) %
            currentPlaylist.length;

    await playSong(
      currentPlaylist[previousIndex],
      playlist: currentPlaylist,
    );
  }

  // Menambahkan atau menghapus Favorite
  void toggleFavorite(Song song) {
    setState(() {
      bool alreadyFavorite = favoriteSongs.any(
            (item) => item.trackId == song.trackId,
      );

      if (alreadyFavorite) {
        favoriteSongs.removeWhere(
              (item) => item.trackId == song.trackId,
        );
      } else {
        favoriteSongs.add(song);
      }
    });
  }

  // Mengecek apakah lagu merupakan Favorite
  bool isFavorite(Song song) {
    return favoriteSongs.any(
          (item) => item.trackId == song.trackId,
    );
  }

  // Format waktu lagu
  String formatDuration(Duration duration) {
    String minutes = duration.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');

    String seconds = duration.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');

    return '$minutes:$seconds';
  }

  // Halaman Detail Lagu / Player
  Widget playerScreen() {
    if (currentSong == null) {
      return Center(
        child: Text(
          'Pilih lagu terlebih dahulu',
          style: TextStyle(
            fontSize: 18,
            color: textColor,
          ),
        ),
      );
    }

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Now Playing',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 30),

                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    currentSong!.artworkUrl,
                    width: 250,
                    height: 250,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.music_note,
                        size: 200,
                        color: pinkColor,
                      );
                    },
                  ),
                ),

                const SizedBox(height: 25),

                // Judul lagu
                Text(
                  currentSong!.trackName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 8),

                // Nama penyanyi
                Text(
                  currentSong!.artistName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: secondaryTextColor,
                  ),
                ),

                const SizedBox(height: 8),

                // Nama album
                Text(
                  currentSong!.collectionName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: secondaryTextColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),

                const SizedBox(height: 20),

                // Waktu lagu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatDuration(currentPosition),
                      style: TextStyle(color: secondaryTextColor),
                    ),
                    Text(
                      formatDuration(totalDuration),
                      style: TextStyle(color: secondaryTextColor),
                    ),
                  ],
                ),

                // Progress bar
                Slider(
                  min: 0,
                  max: totalDuration.inMilliseconds > 0
                      ? totalDuration.inMilliseconds.toDouble()
                      : 1,
                  value: totalDuration.inMilliseconds > 0
                      ? currentPosition.inMilliseconds
                      .clamp(0, totalDuration.inMilliseconds)
                      .toDouble()
                      : 0,
                  activeColor: pinkColor,
                  inactiveColor:
                  isDarkMode ? Colors.white24 : Colors.white70,
                  onChanged: totalDuration.inMilliseconds > 0
                      ? (value) {
                    setState(() {
                      currentPosition = Duration(
                        milliseconds: value.toInt(),
                      );
                    });
                  }
                      : null,
                  onChangeEnd: (value) {
                    player.seek(
                      Duration(milliseconds: value.toInt()),
                    );
                  },
                ),

                const SizedBox(height: 15),

                // Previous, Play/Pause, Next
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: previousSong,
                      icon: Icon(
                        Icons.skip_previous_rounded,
                        size: 45,
                        color: pinkColor,
                      ),
                    ),

                    const SizedBox(width: 15),

                    IconButton(
                      onPressed: () => playSong(
                        currentSong!,
                        playlist: currentPlaylist,
                      ),
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_fill,
                        size: 75,
                        color: pinkColor,
                      ),
                    ),

                    const SizedBox(width: 15),

                    IconButton(
                      onPressed: nextSong,
                      icon: Icon(
                        Icons.skip_next_rounded,
                        size: 45,
                        color: pinkColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // Favorite
                IconButton(
                  onPressed: () {
                    toggleFavorite(currentSong!);
                  },
                  icon: Icon(
                    isFavorite(currentSong!)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: pinkColor,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Mini Player
  Widget miniPlayer() {
    if (currentSong == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTabIndex = 1;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isDarkMode
              ? const Color(0xFF493044)
              : const Color(0xFFFFD6E5),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    currentSong!.artworkUrl,
                    width: 45,
                    height: 45,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 45,
                        height: 45,
                        color: const Color(0xFFFFA6C9),
                        child: const Icon(Icons.music_note),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentSong!.trackName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode
                              ? Colors.white
                              : const Color(0xFF9C2858),
                        ),
                      ),
                      Text(
                        currentSong!.artistName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode
                              ? Colors.white70
                              : const Color(0xFFB34D79),
                        ),
                      ),
                    ],
                  ),
                ),

                IconButton(
                  onPressed: previousSong,
                  icon: const Icon(Icons.skip_previous_rounded),
                  color: const Color(0xFFE84393),
                  iconSize: 27,
                ),

                IconButton(
                  onPressed: () async {
                    if (isPlaying) {
                      await player.pause();
                    } else if (player.state == PlayerState.completed) {
                      await player.seek(Duration.zero);
                      await player.resume();
                    } else {
                      await player.resume();
                    }
                  },
                  icon: Icon(
                    isPlaying
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_fill_rounded,
                  ),
                  color: const Color(0xFFE84393),
                  iconSize: 34,
                ),

                IconButton(
                  onPressed: nextSong,
                  icon: const Icon(Icons.skip_next_rounded),
                  color: const Color(0xFFE84393),
                  iconSize: 27,
                ),
              ],
            ),

            // Slider mini yang bisa digeser
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 5,
                ),
                overlayShape: const RoundSliderOverlayShape(
                  overlayRadius: 10,
                ),
                activeTrackColor: const Color(0xFFE84393),
                inactiveTrackColor:
                isDarkMode ? Colors.white24 : Colors.white,
                thumbColor: const Color(0xFFE84393),
              ),
              child: Slider(
                min: 0,
                max: totalDuration.inMilliseconds > 0
                    ? totalDuration.inMilliseconds.toDouble()
                    : 1,
                value: totalDuration.inMilliseconds > 0
                    ? currentPosition.inMilliseconds
                    .clamp(0, totalDuration.inMilliseconds)
                    .toDouble()
                    : 0,
                onChanged: totalDuration.inMilliseconds > 0
                    ? (value) {
                  setState(() {
                    currentPosition = Duration(
                      milliseconds: value.toInt(),
                    );
                  });
                }
                    : null,
                onChangeEnd: (value) async {
                  await player.seek(
                    Duration(milliseconds: value.toInt()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Halaman Favorite
  Widget favoriteScreen() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Favorite Songs',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: favoriteSongs.isEmpty
                  ? Center(
                child: Text(
                  'Belum ada lagu favorit ❤️',
                  style: TextStyle(color: textColor),
                ),
              )
                  : ListView.builder(
                itemCount: favoriteSongs.length,
                itemBuilder: (context, index) {
                  final song = favoriteSongs[index];

                  bool selected =
                      currentSong?.trackId == song.trackId;

                  return Card(
                    color: selected ? selectedColor : cardColor,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(10),

                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          song.artworkUrl,
                          width: 55,
                          height: 55,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) {
                            return Icon(
                              Icons.music_note,
                              color: pinkColor,
                            );
                          },
                        ),
                      ),

                      title: Text(
                        song.trackName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),

                      subtitle: Text(
                        song.artistName,
                        style: TextStyle(
                          color: secondaryTextColor,
                        ),
                      ),

                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => toggleFavorite(song),
                            icon: Icon(
                              Icons.favorite,
                              color: pinkColor,
                            ),
                          ),

                          IconButton(
                            onPressed: () {
                              playSong(
                                song,
                                playlist: favoriteSongs,
                              );
                            },
                            icon: Icon(
                              selected && isPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_fill,
                              color: pinkColor,
                              size: 32,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [
      HomeScreen(
        songs: songs,
        isLoading: isLoading,
        controller: controller,
        currentSong: currentSong,
        isPlaying: isPlaying,
        favoriteIds: favoriteSongs
            .where((song) => song.trackId != null)
            .map((song) => song.trackId!)
            .toSet(),
        isDarkMode: isDarkMode,
        onPlay: playSong,
        onSearch: carilagu,
        onShowHits: loadHits2026,
        onToggleFavorite: toggleFavorite,
      ),

      playerScreen(),

      favoriteScreen(),

      ProfileScreen(
        isDarkMode: isDarkMode,
        onThemeChanged: (value) {
          setState(() {
            isDarkMode = value;
          });
        },
      ),
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: pages[selectedTabIndex],

      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (currentSong != null && selectedTabIndex != 1)
            miniPlayer(),

          BottomNavigationBar(
            currentIndex: selectedTabIndex,
            onTap: (index) {
              setState(() {
                selectedTabIndex = index;
              });
            },
            backgroundColor: isDarkMode
                ? const Color(0xFF382538)
                : const Color(0xFFFFA6C9),
            selectedItemColor: pinkColor,
            unselectedItemColor: isDarkMode
                ? Colors.white70
                : const Color(0xFF9C2858),
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.play_circle_fill),
                label: 'Player',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite),
                label: 'Favorite',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
