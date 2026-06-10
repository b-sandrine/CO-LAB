import 'opportunity_model.dart';
import 'team_model.dart';
import 'clan_model.dart';
import 'user_model.dart';

class MockData {
  static final UserModel currentUser = UserModel(
    id: 'user_001',
    name: 'Amara Johnson',
    email: 'amara.johnson@alustudent.com',
    degreeProgram: 'Software Engineering',
    yearOfStudy: 3,
    skills: const ['Flutter', 'UI/UX', 'Research', 'Public Speaking', 'Leadership'],
    interests: const ['Hackathons', 'Peer Study', 'Tech Society'],
    leadershipPoints: 340,
    eventsHosted: 3,
    eventsAttended: 12,
    badges: const ['Collaborator', 'Innovator'],
    joinedClanIds: const ['clan_001', 'clan_003'],
    joinedTeamIds: const ['team_003'],
    createdAt: DateTime(2023, 9, 1),
  );

  static final List<OpportunityModel> opportunities = [
    OpportunityModel(
      id: 'opp_001',
      title: 'ALU Tech Society Hackathon',
      description: 'Forming a team. Need: 1 UI Designer + 1 Backend Dev',
      type: 'Hackathon',
      postedBy: 'Kwame',
      postedByInitial: 'K',
      yearLabel: 'CS Year 2',
      eventDate: DateTime(2025, 6, 14),
      skillTags: ['UI Design', 'Flutter', 'Backend'],
      joinLabel: 'Request to Join',
      participantCount: 8,
    ),
    OpportunityModel(
      id: 'opp_002',
      title: 'SE Milestone 2 Study Group',
      description: "Struggling with the brief? Let's tackle it together at Hub 3",
      type: 'Peer Study',
      postedBy: 'Amara',
      postedByInitial: 'A',
      yearLabel: 'Year 3',
      eventDate: DateTime(2025, 6, 9, 16, 0),
      skillTags: [],
      joinLabel: 'RSVP',
      participantCount: 6,
    ),
    const OpportunityModel(
      id: 'opp_003',
      title: 'ALU Debate Club — New Members',
      description: "Open recruitment for next semester's debate team",
      type: 'Club Project',
      postedBy: 'Debate Club',
      postedByInitial: 'D',
      isDateRolling: true,
      skillTags: [],
      joinLabel: 'Requested ✓',
      hasRequested: true,
      participantCount: 14,
    ),
  ];

  static final List<TeamModel> teams = [
    const TeamModel(
      id: 'team_001',
      name: 'Agri-Tech Innovators',
      shortDescription: 'Smart irrigation app for East Africa',
      projectBrief:
          'We are building an IoT-powered smart irrigation system to help smallholder farmers optimize water usage. Our solution uses soil moisture sensors and weather data to provide automated irrigation recommendations, potentially saving up to 40% of water while improving crop yields.',
      members: [
        TeamMember(id: 'm1', name: 'Kwame Mensah', degreeProgram: 'Software Engineering', role: 'Team Lead', initial: 'K'),
        TeamMember(id: 'm2', name: 'Sarah Kimani', degreeProgram: 'Global Challenges', role: 'UI/UX Designer', initial: 'S'),
        TeamMember(id: 'm3', name: 'John Doe', degreeProgram: 'Software Engineering', role: 'Backend Developer', initial: 'J'),
      ],
      openRoles: [
        OpenRole(title: 'UI Designer', description: 'Create mobile app mockups and user flows'),
        OpenRole(title: 'Research Analyst', description: 'Conduct farmer interviews and market research'),
      ],
      skillsNeeded: ['IoT', 'Mobile Development', 'Agriculture', 'Data Analysis'],
    ),
    const TeamModel(
      id: 'team_002',
      name: 'FinLit Squad',
      shortDescription: 'Financial literacy platform for youth',
      projectBrief: 'Building a gamified financial literacy app targeting youth aged 15–25 across Africa.',
      members: [
        TeamMember(id: 'm4', name: 'Ama Owusu', degreeProgram: 'Business Management', role: 'Team Lead', initial: 'A'),
        TeamMember(id: 'm5', name: 'Brice Nkusi', degreeProgram: 'Entrepreneurial Leadership', role: 'Developer', initial: 'A'),
        TeamMember(id: 'm6', name: 'Chloe Eze', degreeProgram: 'Global Challenges', role: 'Content Strategist', initial: 'A'),
        TeamMember(id: 'm7', name: 'David Osei', degreeProgram: 'Business Management', role: 'Finance Analyst', initial: 'A'),
      ],
      openRoles: [
        OpenRole(title: 'Backend Dev', description: 'Build API and database architecture'),
        OpenRole(title: 'Content Writer', description: 'Write financial literacy modules'),
      ],
      skillsNeeded: ['React', 'Finance', 'Writing', 'Marketing'],
    ),
    const TeamModel(
      id: 'team_003',
      name: 'ClimateALU',
      shortDescription: 'Carbon tracking tool for campus',
      projectBrief: 'An app that tracks and gamifies carbon footprint reduction for ALU campus community.',
      members: [
        TeamMember(id: 'm8', name: 'Fatou Diallo', degreeProgram: 'Global Challenges', role: 'Team Lead', initial: 'A'),
        TeamMember(id: 'm9', name: 'Grace Mutua', degreeProgram: 'Software Engineering', role: 'Developer', initial: 'A'),
        TeamMember(id: 'm10', name: 'Hassan Ali', degreeProgram: 'Entrepreneurial Leadership', role: 'Designer', initial: 'A'),
        TeamMember(id: 'm11', name: 'Ife Adeyemi', degreeProgram: 'Global Challenges', role: 'Researcher', initial: 'A'),
      ],
      openRoles: [
        OpenRole(title: 'Data Analyst', description: 'Analyze carbon metrics and build dashboards'),
      ],
      skillsNeeded: ['Data Analysis', 'Python', 'Research', 'UI Design'],
    ),
  ];

  static final now = DateTime.now();

  static final List<ClanModel> clans = [
    ClanModel(
      id: 'clan_001',
      name: 'SE Milestone 2 Study',
      initials: 'SM',
      color: 0xFFCC2027,
      lastMessage: "Don't forget to bring your laptops!",
      lastMessageTime: now.subtract(const Duration(minutes: 2)),
      unreadCount: 3,
      memberCount: 6,
      description: 'Meeting today at Hub 3 — 4:00 PM · Tap for directions',
      messages: [
        ClanMessage(
          id: 'msg1',
          senderId: 'user_kwame',
          senderName: 'Kwame',
          content: "Hey team! Ready for today's session?",
          timestamp: DateTime(2025, 6, 9, 10, 30),
        ),
        ClanMessage(
          id: 'msg2',
          senderId: 'user_001',
          senderName: 'Me',
          content: 'Yes! On my way to Hub 3 now',
          timestamp: DateTime(2025, 6, 9, 10, 32),
          isMe: true,
        ),
        ClanMessage(
          id: 'msg3',
          senderId: 'user_sarah',
          senderName: 'Sarah',
          content: 'Can someone share the study guide?',
          timestamp: DateTime(2025, 6, 9, 10, 35),
        ),
        ClanMessage(
          id: 'msg4',
          senderId: 'user_001',
          senderName: 'Me',
          content: 'I have it! Will bring printed copies',
          timestamp: DateTime(2025, 6, 9, 10, 36),
          isMe: true,
        ),
        ClanMessage(
          id: 'msg5',
          senderId: 'user_kwame',
          senderName: 'Kwame',
          content: 'Perfect! See you all in 30 mins',
          timestamp: DateTime(2025, 6, 9, 10, 40),
        ),
        ClanMessage(
          id: 'msg6',
          senderId: 'user_john',
          senderName: 'John',
          content: '',
          emoji: '🔥',
          timestamp: DateTime(2025, 6, 9, 10, 41),
        ),
      ],
    ),
    ClanModel(
      id: 'clan_002',
      name: 'ClimateALU Team Chat',
      initials: 'CA',
      color: 0xFF00BFA5,
      lastMessage: 'Meeting rescheduled to 5 PM',
      lastMessageTime: now.subtract(const Duration(hours: 1)),
      unreadCount: 0,
      memberCount: 5,
      messages: [],
    ),
    ClanModel(
      id: 'clan_003',
      name: 'ALU Debate Club',
      initials: 'DC',
      color: 0xFF1A1A2E,
      lastMessage: 'Great practice session today!',
      lastMessageTime: now.subtract(const Duration(hours: 3)),
      unreadCount: 1,
      memberCount: 18,
      messages: [],
    ),
    ClanModel(
      id: 'clan_004',
      name: 'Agri-Tech Innovators',
      initials: 'AT',
      color: 0xFFE67E22,
      lastMessage: 'Prototype demo tomorrow at Hub 1',
      lastMessageTime: now.subtract(const Duration(days: 1)),
      unreadCount: 0,
      memberCount: 4,
      messages: [],
    ),
  ];
}
