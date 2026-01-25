import 'package:flutter/material.dart';

class EventModel {
  final String title;
  final String time;
  final String host;
  final String location;
  final String participants;
  final String status;
  final String imageUrl;
  final List<Color> themeColors;

  EventModel({
    required this.title,
    required this.time,
    required this.host,
    required this.location,
    required this.participants,
    required this.status,
    required this.imageUrl,
    required this.themeColors,
  });
}