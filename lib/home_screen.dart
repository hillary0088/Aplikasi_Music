import 'package:flutter/material.dart';
import 'song.dart';

class HomeScreen extends StatelessWidget {
  final List<Song> songs;
  final bool isLoading;
  final TextEditingController controller;
  final Song? currentSong;
  final bool isPlaying;
  final Set<int> favoriteIds;
  final bool isDarkMode;

  final Function(Song) onPlay;
  final Function(Song) onToggleFavorite;
  final VoidCallback onSearch;
  final VoidCallback onShowHits;

  const HomeScreen({
    super.key,
    required this.songs,
    required this.isLoading,
    required this.controller,
    required this.currentSong,
    required this.isPlaying,
    required this.favoriteIds,
    required this.isDarkMode,
    required this.onPlay,
    required this.onToggleFavorite,
    required this.onSearch,
    required this.onShowHits,
  });

  Color get textColor => isDarkMode
      ? const Color(0xFFFFD6E5)
      : const Color(0xFF9C2858);

  Color get secondaryTextColor => isDarkMode
      ? const Color(0xFFE5AFC9)
      : const Color(0xFFB34D79);

  Color get cardColor => isDarkMode
      ? const Color(0xFF493044)
      : const Color(0xFFFFD6E5);

  Color get selectedColor => isDarkMode
      ? const Color(0xFF70415D)
      : const Color(0xFFFF8FBA);

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;

    final greeting = hour < 11
        ? 'Good morning, little fairy ✨'
        : hour < 15
        ? 'Hello, lovely! 🌷'
        : hour < 18
        ? 'Hope your day feels magical ♡'
        : 'Good evening, dreamer 🌙';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nama aplikasi
            Text(
              'HYtune',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),

            const SizedBox(height: 5),

            // Greeting fairy
            Text(
              greeting,
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 15,
                fontStyle: FontStyle.italic,
              ),
            ),

            const SizedBox(height: 20),

            // Search lagu
            TextField(
              controller: controller,
              onSubmitted: (_) => onSearch(),
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Cari lagu atau penyanyi...',
                hintStyle: TextStyle(
                  color: secondaryTextColor,
                ),
                filled: true,
                fillColor: isDarkMode
                    ? const Color(0xFF493044)
                    : const Color(0xFFFFE0EB),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFFE84393),
                ),
                suffixIcon: IconButton(
                  onPressed: onSearch,
                  icon: const Icon(
                    Icons.arrow_forward,
                    color: Color(0xFFE84393),
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Judul Hits
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hits 2026',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),

                TextButton(
                  onPressed: onShowHits,
                  child: const Text(
                    'Lihat Hits',
                    style: TextStyle(
                      color: Color(0xFFE84393),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Daftar lagu
            Expanded(
              child: isLoading
                  ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFE84393),
                ),
              )
                  : songs.isEmpty
                  ? Center(
                child: Text(
                  'Lagu tidak ditemukan',
                  style: TextStyle(color: textColor),
                ),
              )
                  : ListView.builder(
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  final song = songs[index];

                  bool selected =
                      currentSong?.trackId == song.trackId;

                  bool favorite = song.trackId != null &&
                      favoriteIds.contains(song.trackId);

                  return Card(
                    color: selected
                        ? selectedColor
                        : cardColor,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(10),

                      // Album cover
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          song.artworkUrl,
                          width: 55,
                          height: 55,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) {
                            return const Icon(
                              Icons.music_note,
                              size: 50,
                              color: Color(0xFFE84393),
                            );
                          },
                        ),
                      ),

                      // Judul lagu
                      title: Text(
                        song.trackName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),

                      // Nama penyanyi
                      subtitle: Text(
                        song.artistName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: secondaryTextColor,
                        ),
                      ),

                      // Favorite dan Play
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () {
                              onToggleFavorite(song);
                            },
                            icon: Icon(
                              favorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: const Color(0xFFE84393),
                            ),
                          ),

                          IconButton(
                            onPressed: () => onPlay(song),
                            icon: Icon(
                              selected && isPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_fill,
                              size: 35,
                              color: const Color(0xFFE84393),
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
}