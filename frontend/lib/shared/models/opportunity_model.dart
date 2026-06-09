class OpportunityModel {
  final String id;
  final String title;
  final String description;
  final String type;
  final String postedBy;
  final String postedByInitial;
  final String? yearLabel;
  final DateTime? eventDate;
  final bool isDateRolling;
  final List<String> skillTags;
  final String joinLabel;
  final bool hasRequested;
  final int participantCount;
  final bool isSaved;

  const OpportunityModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.postedBy,
    required this.postedByInitial,
    this.yearLabel,
    this.eventDate,
    this.isDateRolling = false,
    this.skillTags = const [],
    required this.joinLabel,
    this.hasRequested = false,
    this.participantCount = 0,
    this.isSaved = false,
  });

  OpportunityModel copyWith({bool? isSaved, bool? hasRequested}) {
    return OpportunityModel(
      id: id,
      title: title,
      description: description,
      type: type,
      postedBy: postedBy,
      postedByInitial: postedByInitial,
      yearLabel: yearLabel,
      eventDate: eventDate,
      isDateRolling: isDateRolling,
      skillTags: skillTags,
      joinLabel: joinLabel,
      hasRequested: hasRequested ?? this.hasRequested,
      participantCount: participantCount,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}
