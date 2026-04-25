// lib/models/event_model.dart
import 'package:flutter/material.dart';

class EventModel {
  final int eventId;
  final String title;
  final String description;
  final String status;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime? submissionDeadline;
  final String? creatorAvatarUrl;
  final int participantCount;
  final String creatorName;
  final String? thumbnailUrl;
  final double totalPrizePool;
  final bool isJoined;
  final String? myExpertStatus;
  final double appliedFee;
  final double expertWeight;
  final double userWeight;
  final double entryFee;
  final List<PrizeModel> prizes;
  final List<ExpertModel> experts;

  EventModel({
    required this.eventId,
    required this.title,
    required this.description,
    required this.status,
    required this.startTime,
    required this.endTime,
    this.submissionDeadline,
    this.creatorAvatarUrl,
    required this.participantCount,
    required this.creatorName,
    this.thumbnailUrl,
    required this.totalPrizePool,
    required this.isJoined,
    this.myExpertStatus,
    required this.appliedFee,
    required this.expertWeight,
    required this.userWeight,
    this.prizes = const [],
    this.experts = const [],
    required this.entryFee,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      eventId: json['eventId'] ?? 0,
      title: json['title'] ?? "No Title",
      description: json['description'] ?? "",
      status: json['status'] ?? "Unknown",
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      submissionDeadline: json['submissionDeadline'] != null
          ? DateTime.parse(json['submissionDeadline'])
          : null,
      participantCount: json['participantCount'] ?? 0,
      creatorName: json['creatorName'] ?? "Anonymous",
      thumbnailUrl: json['thumbnailUrl'],
      totalPrizePool: (json['totalPrizePool'] as num?)?.toDouble() ?? 0.0,
      isJoined: json['isJoined'] == true,
      myExpertStatus: json['myExpertStatus'],
      appliedFee: (json['appliedFee'] as num?)?.toDouble() ?? 0.0,
      expertWeight: (json['expertWeight'] as num?)?.toDouble() ?? 0.0,
      userWeight: (json['userWeight'] as num?)?.toDouble() ?? 0.0,
      prizes: (json['prizes'] as List?)?.map((p) => PrizeModel.fromJson(p)).toList() ?? [],
      experts: (json['experts'] as List?)?.map((e) => ExpertModel.fromJson(e)).toList() ?? [],
      creatorAvatarUrl: json['creatorAvatarUrl'],
      entryFee: (json['entryFee'] ?? 0).toDouble(),
    );
  }

  String get imageUrl => thumbnailUrl ?? "https://images.unsplash.com/photo-1492684223066-81342ee5ff30?q=80&w=2070";

  List<Color> get themeColors {
    if (status == "Active" || status == "Inviting") return [Colors.purpleAccent, Colors.blueAccent];
    if (status == "Completed") return [Colors.cyanAccent, Colors.greenAccent];
    return [Colors.orangeAccent, Colors.pinkAccent];
  }
}

class PrizeModel {
  final int? prizeEventId;
  final int ranked;
  final double rewardAmount;
  final String status;

  PrizeModel({this.prizeEventId, required this.ranked, required this.rewardAmount, this.status = "Active"});

  factory PrizeModel.fromJson(Map<String, dynamic> json) {
    return PrizeModel(
      prizeEventId: json['prizeEventId'],
      ranked: json['ranked'] ?? 0,
      rewardAmount: (json['rewardAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? "Active",
    );
  }
}

class ExpertModel {
  final int expertId;
  final String fullName;
  final String? avatarUrl;
  final String status;

  ExpertModel({required this.expertId, required this.fullName,this.avatarUrl, this.status = "Accepted"});

  factory ExpertModel.fromJson(Map<String, dynamic> json) {
    return ExpertModel(
      expertId: json['expertId'] ?? 0,
      fullName: json['fullName'] ?? "Chuyên gia",
      avatarUrl: json['avatarUrl'],
      status: json['status'] ?? "Accepted",
    );
  }
}