class TeamMember {
  final String id;
  final String name;
  final String degreeProgram;
  final String role;
  final String initial;

  const TeamMember({
    required this.id,
    required this.name,
    required this.degreeProgram,
    required this.role,
    required this.initial,
  });
}

class OpenRole {
  final String title;
  final String description;

  const OpenRole({required this.title, required this.description});
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

  const TeamModel({
    required this.id,
    required this.name,
    required this.projectBrief,
    required this.shortDescription,
    required this.members,
    required this.openRoles,
    required this.skillsNeeded,
    this.isOpen = true,
  });

  List<String> get neededRoleNames => openRoles.map((r) => r.title).toList();
  int get memberCount => members.length;
  List<String> get memberInitials => members.map((m) => m.initial).toList();
}
