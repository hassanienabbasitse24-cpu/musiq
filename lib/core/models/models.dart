import 'package:flutter/material.dart';

class Song {
  final String id;
  final String title;
  final String titleAr;
  final String artist;
  final String artistAr;
  final String? imageUrl;
  final String? previewUrl;
  final String? audioUrl;
  final String? videoId;
  final Duration? duration;

  const Song({
    required this.id,
    required this.title,
    required this.titleAr,
    required this.artist,
    required this.artistAr,
    this.imageUrl,
    this.previewUrl,
    this.audioUrl,
    this.videoId,
    this.duration,
  });
}

class Artist {
  final String id;
  final String name;
  final String nameAr;
  final String? imageUrl;
  final Color backgroundColor;

  const Artist({
    required this.id,
    required this.name,
    required this.nameAr,
    this.imageUrl,
    required this.backgroundColor,
  });
}

class Playlist {
  final String id;
  final String title;
  final String titleAr;
  final String? imageUrl;
  final List<String> collageImages;
  final Color backgroundColor;
  final String subtitle;
  final String subtitleAr;

  const Playlist({
    required this.id,
    required this.title,
    required this.titleAr,
    this.imageUrl,
    this.collageImages = const [],
    required this.backgroundColor,
    required this.subtitle,
    required this.subtitleAr,
  });
}
