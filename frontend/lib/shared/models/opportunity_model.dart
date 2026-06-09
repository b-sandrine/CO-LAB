import '../../core/database/database_service.dart';

class OpportunityModel {
  final String id;
  final String title;
  final String description;
  final String type;
  final String postedBy;
  final String postedByInitial;
  final String? postedById;
  final String? yearLabel;
  final DateTime? eventDate;
  final bool isDateRolling;
  final List<String> skillTags;
  final String joinLabel;
  final bool hasRequested;
  final int participantCount;
  final bool isSaved;
  final String? location;
  final bool openToAll;

  const OpportunityModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.postedBy,
    required this.postedByInitial,
    this.postedById,
    this.yearLabel,
    this.eventDate,
    this.isDateRolling = false,
    this.skillTags = const [],
    required this.joinLabel,
    this.hasRequested = false,
    this.participantCount = 0,
    this.isSaved = false,
    this.location,
    this.openToAll = true,
  });

  factory OpportunityModel.fromMap(Map<String, dynamic> map, String id) {
    final postedBy = map['postedBy'] as String? ?? '';
    return OpportunityModel(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      type: map['type'] as String? ?? 'Hackathon',
      postedBy: postedBy,
      postedByInitial: map['postedByInitial'] as String? ??
          (postedBy.isNotEmpty ? postedBy[0].toUpperCase() : '?'),
      postedById: map['postedById'] as String?,
      yearLabel: map['yearLabel'] as String?,
      eventDate: map['eventDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['eventDate'] as int)
          : null,
      isDateRolling: (map['isDateRolling'] as int? ?? 0) == 1,
      skillTags: DatabaseService.decodeStringList(map['skillTags']),
      joinLabel: map['joinLabel'] as String? ?? 'Request to Join',
      participantCount: (map['participantCount'] as int?) ?? 0,
      location: map['location'] as String?,
      openToAll: (map['openToAll'] as int? ?? 1) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'type': type,
      'postedBy': postedBy,
      'postedByInitial': postedByInitial,
      'postedById': postedById,
      'yearLabel': yearLabel,
      'eventDate': eventDate?.millisecondsSinceEpoch,
      'isDateRolling': isDateRolling ? 1 : 0,
      'skillTags': DatabaseService.encodeList(skillTags),
      'joinLabel': joinLabel,
      'participantCount': participantCount,
      'location': location,
      'openToAll': openToAll ? 1 : 0,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  OpportunityModel copyWith({bool? isSaved, bool? hasRequested, String? joinLabel, int? participantCount}) {
    return OpportunityModel(
      id: id,
      title: title,
      description: description,
      type: type,
      postedBy: postedBy,
      postedByInitial: postedByInitial,
      postedById: postedById,
      yearLabel: yearLabel,
      eventDate: eventDate,
      isDateRolling: isDateRolling,
      skillTags: skillTags,
      joinLabel: joinLabel ?? this.joinLabel,
      hasRequested: hasRequested ?? this.hasRequested,
      participantCount: participantCount ?? this.participantCount,
      isSaved: isSaved ?? this.isSaved,
      location: location,
      openToAll: openToAll,
    );
  }
}
