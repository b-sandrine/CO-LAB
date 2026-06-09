import 'package:equatable/equatable.dart';
import '../../core/database/database_service.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String? bio;
  final String degreeProgram;
  final int yearOfStudy;
  final List<String> skills;
  final List<String> interests;
  final int leadershipPoints;
  final int eventsHosted;
  final int eventsAttended;
  final List<String> badges;
  final List<String> joinedClanIds;
  final List<String> joinedTeamIds;
  final String role;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.bio,
    required this.degreeProgram,
    this.yearOfStudy = 1,
    this.skills = const [],
    this.interests = const [],
    this.leadershipPoints = 0,
    this.eventsHosted = 0,
    this.eventsAttended = 0,
    this.badges = const [],
    this.joinedClanIds = const [],
    this.joinedTeamIds = const [],
    this.role = 'student',
    required this.createdAt,
  });

  String get firstName => name.split(' ').first;
  String get initials => name.isNotEmpty
      ? name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
      : '?';

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['fullName'] as String? ?? map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      bio: map['bio'] as String?,
      degreeProgram: map['degreeProgram'] as String? ?? '',
      yearOfStudy: (map['yearOfStudy'] as int?) ?? 1,
      skills: DatabaseService.decodeStringList(map['skills']),
      interests: DatabaseService.decodeStringList(map['interests']),
      leadershipPoints: (map['leadershipPoints'] as int?) ?? 0,
      eventsHosted: (map['eventsHosted'] as int?) ?? 0,
      eventsAttended: (map['eventsAttended'] as int?) ?? 0,
      badges: DatabaseService.decodeStringList(map['badges']),
      joinedClanIds: DatabaseService.decodeStringList(map['joinedClanIds']),
      joinedTeamIds: DatabaseService.decodeStringList(map['joinedTeamIds']),
      role: map['role'] as String? ?? 'student',
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': name,
      'email': email,
      'photoUrl': photoUrl,
      'bio': bio,
      'degreeProgram': degreeProgram,
      'yearOfStudy': yearOfStudy,
      'skills': DatabaseService.encodeList(skills),
      'interests': DatabaseService.encodeList(interests),
      'leadershipPoints': leadershipPoints,
      'eventsHosted': eventsHosted,
      'eventsAttended': eventsAttended,
      'badges': DatabaseService.encodeList(badges),
      'joinedClanIds': DatabaseService.encodeList(joinedClanIds),
      'joinedTeamIds': DatabaseService.encodeList(joinedTeamIds),
      'role': role,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    bool clearPhotoUrl = false,
    String? bio,
    String? degreeProgram,
    int? yearOfStudy,
    List<String>? skills,
    List<String>? interests,
    int? leadershipPoints,
    int? eventsHosted,
    int? eventsAttended,
    List<String>? badges,
    List<String>? joinedClanIds,
    List<String>? joinedTeamIds,
    String? role,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: clearPhotoUrl ? null : (photoUrl ?? this.photoUrl),
      bio: bio ?? this.bio,
      degreeProgram: degreeProgram ?? this.degreeProgram,
      yearOfStudy: yearOfStudy ?? this.yearOfStudy,
      skills: skills ?? this.skills,
      interests: interests ?? this.interests,
      leadershipPoints: leadershipPoints ?? this.leadershipPoints,
      eventsHosted: eventsHosted ?? this.eventsHosted,
      eventsAttended: eventsAttended ?? this.eventsAttended,
      badges: badges ?? this.badges,
      joinedClanIds: joinedClanIds ?? this.joinedClanIds,
      joinedTeamIds: joinedTeamIds ?? this.joinedTeamIds,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, email, degreeProgram, leadershipPoints];
}
