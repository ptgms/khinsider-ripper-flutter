class AlbumStruct {
  final String albumName;
  final String albumLink;
  final String albumCover;
  const AlbumStruct(this.albumName, this.albumLink, this.albumCover);
}

class AlbumTags {
  final List<String> tracks; // List<String>
  final List<String> trackDuration; // [String]
  final String albumName; // String
  final String albumLink;
  final List<String> trackURL; // [String]
  final List<String> coverURL; // [String]

  final bool mp3;
  final bool flac;
  final bool ogg;

  final List<String> tags; // [String]
  final List<String> trackSizeMP3; // [String]
  final List<String> trackSizeFLAC; // [String]
  final List<String> trackSizeOGG; // [String]

  const AlbumTags(this.tracks, this.trackDuration, this.albumName, this.albumLink, this.trackURL, this.coverURL, this.mp3, this.flac,
      this.ogg, this.tags, this.trackSizeMP3, this.trackSizeFLAC, this.trackSizeOGG);
}
