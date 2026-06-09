import '../../core/database/database_service.dart';

class TeamMember {
  final String id;
  final String name;
  final String degreeProgram;
  final String role;
  final String initial;
  final String? photoUrl;

  const TeamMember({
    required this.id,
    required this.name,
    required this.degreeProgram,
    required this.role,
    required this.initial,
    this.photoUrl,
  });

  factory TeamMember.fromMap(Map<String, dynamic> map, String id) {
    final name = map['name'] as String? ?? '';
    return TeamMember(
      id: id,
      name: name,
      degreeProgram: map['degreeProgram'] as String? ?? '',
      role: map['role'] as String? ?? 'Member',
      initial: map['initial'] as String? ?? (name.isNotEmpty ? name[0].toUpperCase() : '?'),
      photoUrl: map['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'initial': initial,
    'degreeProgram': degreeProgram,
    'role': role,
    'photoUrl': photoUrl,
  };
}

class OpenRole {
  final String title;
  final String description;

  const OpenRole({required this.title, required this.description});

  factory OpenRole.fromMap(Map<String, dynamic> map) => OpenRole(
    title: map['title'] as String? ?? '',
    description: map['description'] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {'title': title, 'description': description};
}

class TeamModel {
  final String id;
  final String name;
  final String projectBrief;
  final String shortDescription;
  final List<TeamMember> members;
  final List<OpenRole> openRoles;
  final List<String> skillsNeeded;
  final bool isOpen;
  final String? ownerId;
  final DateTime? createdAt;

  const TeamModel({
    required this.id,
    required this.name,
    required this.projectBrief,
    required this.shortDescription,
    required this.members,
    required this.openRoles,
    required this.skillsNeeded,
    this.isOpen = true,
    this.ownerId,
    this.createdAt,
  });

  List<String> get neededRoleNames => openRoles.map((r) => r.title).toList();
  int get memberCount => members.length;
  List<String> get memberInitials => members.map((m) => m.initial).toList();

  factory TeamModel.fromMap(Map<String, dynamic> map, String id) {
    final openRolesData = DatabaseService.decodeMapList(map['openRoles']);
    final openRolesList = openRolesData.map(OpenRole.fromMap).toList();

    return TeamModel(
      id: id,
      name: map['title'] as String? ?? map['name'] as String? ?? '',
      projectBrief: map['description'] as String? ?? map['projectBrief'] as String? ?? '',
      shortDescription: map['shortDescription'] as String? ?? '',
      members: const [],
      openRoles: openRolesList,
      skillsNeeded: DatabaseService.decodeStringList(map['requiredSkills'] ?? map['skillsNeeded']),
      isOpen: (map['isOpen'] as int? ?? 1) == 1,
      ownerId: map['ownerId'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'title': name,
    'description': projectBrief,
    'shortDescription': shortDescription,
    'openRoles': DatabaseService.encodeList(openRoles.map((r) => r.toMap()).toList()),
    'requiredSkills': DatabaseService.encodeList(skillsNeeded),
    'isOpen': isOpen ? 1 : 0,
    'ownerId': ownerId,
    'createdAt': DateTime.now().millisecondsSinceEpoch,
  };

  TeamModel copyWith({List<TeamMember>? members}) => TeamModel(
    id: id,
    name: name,
    projectBrief: projectBrief,
    shortDescription: shortDescription,
    members: members ?? this.members,
    openRoles: openRoles,
    skillsNeeded: skillsNeeded,
    isOpen: isOpen,
    ownerId: ownerId,
    createdAt: createdAt,
  );
}
