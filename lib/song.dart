
class Song {
  final int? trackId;
  final String trackName;
  final String artistName;
  final String collectionName;
  final String artworkUrl;
  final String? previewUrl;

  Song({
    this.trackId,
    required this.trackName,
    required this.artistName,
    required this.collectionName,
    required this.artworkUrl,
    this.previewUrl,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      trackId: int.tryParse(json['trackId'].toString()),
      trackName: json['trackName'] ?? '-',
      artistName: json['artistName'] ?? '-',
      collectionName: json['collectionName'] ?? '-',
      artworkUrl: json['artworkUrl100'] ?? '',
      previewUrl: json['previewUrl'],
    );
  }
}
