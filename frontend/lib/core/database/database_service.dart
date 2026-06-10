import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'alu_colab.db');
    return openDatabase(
      path,
      version: 3,
      onCreate: _create,
      onUpgrade: _upgrade,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future<void> _upgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          'ALTER TABLE users ADD COLUMN onboardingCompleted INTEGER DEFAULT 0');
    }
    if (oldVersion < 3) {
      final now = DateTime.now().millisecondsSinceEpoch;
      await _seedTeams(db, now);

      // Auto-join all existing users into the default clans
      final users = await db.query('users', columns: ['id']);
      const defaultClanIds = ['clan_tech', 'clan_design', 'clan_biz', 'clan_data'];
      for (final user in users) {
        final userId = user['id'] as String;
        for (final clanId in defaultClanIds) {
          final existing = await db.query('clan_members',
              where: 'clanId = ? AND userId = ?', whereArgs: [clanId, userId]);
          if (existing.isEmpty) {
            await db.insert('clan_members', {
              'id': '${clanId}_$userId',
              'clanId': clanId,
              'userId': userId,
              'joinedAt': now,
            }, conflictAlgorithm: ConflictAlgorithm.ignore);
            await db.rawUpdate(
                'UPDATE clans SET memberCount = memberCount + 1 WHERE id = ?',
                [clanId]);
          }
        }
      }
    }
  }

  Future<void> _create(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        fullName TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        passwordHash TEXT NOT NULL,
        degreeProgram TEXT DEFAULT '',
        yearOfStudy INTEGER DEFAULT 1,
        bio TEXT,
        photoUrl TEXT,
        role TEXT DEFAULT 'student',
        skills TEXT DEFAULT '[]',
        interests TEXT DEFAULT '[]',
        joinedClanIds TEXT DEFAULT '[]',
        joinedTeamIds TEXT DEFAULT '[]',
        leadershipPoints INTEGER DEFAULT 0,
        eventsHosted INTEGER DEFAULT 0,
        eventsAttended INTEGER DEFAULT 0,
        badges TEXT DEFAULT '[]',
        onboardingCompleted INTEGER DEFAULT 0,
        createdAt INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE opportunities (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        type TEXT NOT NULL,
        postedBy TEXT NOT NULL,
        postedByInitial TEXT NOT NULL,
        postedById TEXT,
        yearLabel TEXT,
        eventDate INTEGER,
        isDateRolling INTEGER DEFAULT 0,
        skillTags TEXT DEFAULT '[]',
        joinLabel TEXT DEFAULT 'Request to Join',
        participantCount INTEGER DEFAULT 0,
        location TEXT,
        openToAll INTEGER DEFAULT 1,
        createdAt INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE registrations (
        id TEXT PRIMARY KEY,
        eventId TEXT NOT NULL,
        userId TEXT NOT NULL,
        status TEXT DEFAULT 'confirmed',
        createdAt INTEGER NOT NULL,
        UNIQUE(eventId, userId)
      )
    ''');

    await db.execute('''
      CREATE TABLE projects (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        shortDescription TEXT DEFAULT '',
        ownerId TEXT,
        ownerName TEXT DEFAULT '',
        openRoles TEXT DEFAULT '[]',
        requiredSkills TEXT DEFAULT '[]',
        isOpen INTEGER DEFAULT 1,
        memberCount INTEGER DEFAULT 1,
        createdAt INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE project_members (
        id TEXT PRIMARY KEY,
        projectId TEXT NOT NULL,
        userId TEXT NOT NULL,
        name TEXT NOT NULL,
        initial TEXT NOT NULL,
        role TEXT DEFAULT 'Member',
        degreeProgram TEXT DEFAULT '',
        photoUrl TEXT,
        UNIQUE(projectId, userId)
      )
    ''');

    await db.execute('''
      CREATE TABLE project_applications (
        id TEXT PRIMARY KEY,
        projectId TEXT NOT NULL,
        applicantId TEXT NOT NULL,
        applicantName TEXT NOT NULL,
        selectedRole TEXT NOT NULL,
        message TEXT DEFAULT '',
        status TEXT DEFAULT 'pending',
        createdAt INTEGER NOT NULL,
        UNIQUE(projectId, applicantId)
      )
    ''');

    await db.execute('''
      CREATE TABLE clans (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        category TEXT,
        ownerId TEXT,
        memberCount INTEGER DEFAULT 0,
        lastMessage TEXT DEFAULT '',
        color INTEGER NOT NULL,
        imageUrl TEXT,
        updatedAt INTEGER NOT NULL,
        createdAt INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE clan_members (
        id TEXT PRIMARY KEY,
        clanId TEXT NOT NULL,
        userId TEXT NOT NULL,
        joinedAt INTEGER NOT NULL,
        UNIQUE(clanId, userId)
      )
    ''');

    await db.execute('''
      CREATE TABLE clan_messages (
        id TEXT PRIMARY KEY,
        clanId TEXT NOT NULL,
        senderId TEXT NOT NULL,
        senderName TEXT NOT NULL,
        content TEXT DEFAULT '',
        imageUrl TEXT,
        emoji TEXT,
        createdAt INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE notifications (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        type TEXT NOT NULL,
        isRead INTEGER DEFAULT 0,
        referenceId TEXT,
        createdAt INTEGER NOT NULL
      )
    ''');

    await _seed(db);
  }

  Future<void> _seedTeams(Database db, int now) async {
    final teams = [
      {
        'id': 'team_seed_001',
        'title': 'Agri-Tech Innovators',
        'description': 'Building an IoT-powered smart irrigation system to help smallholder farmers optimize water usage using soil moisture sensors and weather data.',
        'shortDescription': 'Smart irrigation app for East Africa',
        'ownerId': null,
        'ownerName': 'Kwame Mensah',
        'openRoles': jsonEncode([
          {'title': 'UI Designer', 'description': 'Create mobile app mockups and user flows'},
          {'title': 'Research Analyst', 'description': 'Conduct farmer interviews and market research'},
        ]),
        'requiredSkills': jsonEncode(['IoT', 'Mobile Development', 'Agriculture', 'Data Analysis']),
        'isOpen': 1,
        'memberCount': 3,
        'createdAt': now,
      },
      {
        'id': 'team_seed_002',
        'title': 'FinLit Squad',
        'description': 'Building a gamified financial literacy app targeting youth aged 15–25 across Africa.',
        'shortDescription': 'Financial literacy platform for youth',
        'ownerId': null,
        'ownerName': 'Ama Owusu',
        'openRoles': jsonEncode([
          {'title': 'Backend Dev', 'description': 'Build API and database architecture'},
          {'title': 'Content Writer', 'description': 'Write financial literacy modules'},
        ]),
        'requiredSkills': jsonEncode(['React', 'Finance', 'Writing', 'Marketing']),
        'isOpen': 1,
        'memberCount': 4,
        'createdAt': now - 86400000,
      },
      {
        'id': 'team_seed_003',
        'title': 'ClimateALU',
        'description': 'An app that tracks and gamifies carbon footprint reduction for the ALU campus community.',
        'shortDescription': 'Carbon tracking tool for campus',
        'ownerId': null,
        'ownerName': 'Fatou Diallo',
        'openRoles': jsonEncode([
          {'title': 'Data Analyst', 'description': 'Analyze carbon metrics and build dashboards'},
        ]),
        'requiredSkills': jsonEncode(['Data Analysis', 'Python', 'Research', 'UI Design']),
        'isOpen': 1,
        'memberCount': 4,
        'createdAt': now - 172800000,
      },
    ];

    for (final team in teams) {
      await db.insert('projects', team, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    final members = [
      {'id': 'pm1', 'projectId': 'team_seed_001', 'userId': 'seed_m1', 'name': 'Kwame Mensah', 'initial': 'K', 'role': 'Team Lead', 'degreeProgram': 'Software Engineering'},
      {'id': 'pm2', 'projectId': 'team_seed_001', 'userId': 'seed_m2', 'name': 'Sarah Kimani', 'initial': 'S', 'role': 'UI/UX Designer', 'degreeProgram': 'Global Challenges'},
      {'id': 'pm3', 'projectId': 'team_seed_001', 'userId': 'seed_m3', 'name': 'John Doe', 'initial': 'J', 'role': 'Backend Developer', 'degreeProgram': 'Software Engineering'},
      {'id': 'pm4', 'projectId': 'team_seed_002', 'userId': 'seed_m4', 'name': 'Ama Owusu', 'initial': 'A', 'role': 'Team Lead', 'degreeProgram': 'Business Management'},
      {'id': 'pm5', 'projectId': 'team_seed_002', 'userId': 'seed_m5', 'name': 'Brice Nkusi', 'initial': 'B', 'role': 'Developer', 'degreeProgram': 'Entrepreneurial Leadership'},
      {'id': 'pm6', 'projectId': 'team_seed_002', 'userId': 'seed_m6', 'name': 'Chloe Eze', 'initial': 'C', 'role': 'Content Strategist', 'degreeProgram': 'Global Challenges'},
      {'id': 'pm7', 'projectId': 'team_seed_002', 'userId': 'seed_m7', 'name': 'David Osei', 'initial': 'D', 'role': 'Finance Analyst', 'degreeProgram': 'Business Management'},
      {'id': 'pm8', 'projectId': 'team_seed_003', 'userId': 'seed_m8', 'name': 'Fatou Diallo', 'initial': 'F', 'role': 'Team Lead', 'degreeProgram': 'Global Challenges'},
      {'id': 'pm9', 'projectId': 'team_seed_003', 'userId': 'seed_m9', 'name': 'Grace Mutua', 'initial': 'G', 'role': 'Developer', 'degreeProgram': 'Software Engineering'},
      {'id': 'pm10', 'projectId': 'team_seed_003', 'userId': 'seed_m10', 'name': 'Hassan Ali', 'initial': 'H', 'role': 'Designer', 'degreeProgram': 'Entrepreneurial Leadership'},
      {'id': 'pm11', 'projectId': 'team_seed_003', 'userId': 'seed_m11', 'name': 'Ife Adeyemi', 'initial': 'I', 'role': 'Researcher', 'degreeProgram': 'Global Challenges'},
    ];

    for (final member in members) {
      await db.insert('project_members', member, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<void> _seed(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Seed default clans
    final clans = [
      {
        'id': 'clan_tech',
        'name': 'Tech Builders',
        'description': 'Where ALU engineers build the future',
        'category': 'Technology',
        'ownerId': null,
        'memberCount': 0,
        'lastMessage': 'Welcome to Tech Builders!',
        'color': 0xFF1A73E8,
        'imageUrl': null,
        'updatedAt': now,
        'createdAt': now,
      },
      {
        'id': 'clan_design',
        'name': 'Design Minds',
        'description': 'UI/UX and product design enthusiasts',
        'category': 'Design',
        'ownerId': null,
        'memberCount': 0,
        'lastMessage': 'Welcome to Design Minds!',
        'color': 0xFFCC2027,
        'imageUrl': null,
        'updatedAt': now,
        'createdAt': now,
      },
      {
        'id': 'clan_biz',
        'name': 'Venture Lab',
        'description': 'Aspiring entrepreneurs and business leaders',
        'category': 'Business',
        'ownerId': null,
        'memberCount': 0,
        'lastMessage': 'Welcome to Venture Lab!',
        'color': 0xFF2E7D32,
        'imageUrl': null,
        'updatedAt': now,
        'createdAt': now,
      },
      {
        'id': 'clan_data',
        'name': 'Data & AI Guild',
        'description': 'Machine learning, data science and analytics',
        'category': 'Data Science',
        'ownerId': null,
        'memberCount': 0,
        'lastMessage': 'Welcome to Data & AI Guild!',
        'color': 0xFF6A1B9A,
        'imageUrl': null,
        'updatedAt': now,
        'createdAt': now,
      },
    ];

    for (final clan in clans) {
      await db.insert('clans', clan, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    // Seed a sample hackathon opportunity
    await db.insert('opportunities', {
      'id': 'opp_seed_1',
      'title': 'ALU Innovation Hackathon',
      'description': 'Build solutions addressing African challenges in 48 hours. Open to all ALU students.',
      'type': 'Hackathon',
      'postedBy': 'ALU Events Team',
      'postedByInitial': 'A',
      'postedById': null,
      'yearLabel': null,
      'eventDate': DateTime.now().add(const Duration(days: 14)).millisecondsSinceEpoch,
      'isDateRolling': 0,
      'skillTags': jsonEncode(['Flutter', 'Python', 'UI Design', 'Business']),
      'joinLabel': 'Request to Join',
      'participantCount': 0,
      'location': 'ALU Kigali Campus',
      'openToAll': 1,
      'createdAt': now,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    // Seed a peer study opportunity
    await db.insert('opportunities', {
      'id': 'opp_seed_2',
      'title': 'Machine Learning Study Circle',
      'description': 'Weekly deep-dives into ML fundamentals. We cover papers and hands-on projects together.',
      'type': 'Peer Study',
      'postedBy': 'ALU Events Team',
      'postedByInitial': 'A',
      'postedById': null,
      'yearLabel': null,
      'eventDate': DateTime.now().add(const Duration(days: 3)).millisecondsSinceEpoch,
      'isDateRolling': 1,
      'skillTags': jsonEncode(['Python', 'Machine Learning', 'Statistics']),
      'joinLabel': 'Request to Join',
      'participantCount': 0,
      'location': 'Library Room B',
      'openToAll': 1,
      'createdAt': now,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    await _seedTeams(db, now);
  }

  // Helper: encode list to JSON string for storage
  static String encodeList(List<dynamic> list) => jsonEncode(list);

  // Helper: decode JSON string to List<String>
  static List<String> decodeStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return List<String>.from(value);
    try {
      return List<String>.from(jsonDecode(value as String) as List);
    } catch (_) {
      return [];
    }
  }

  // Helper: decode JSON string to List<Map>
  static List<Map<String, dynamic>> decodeMapList(dynamic value) {
    if (value == null) return [];
    if (value is List) return List<Map<String, dynamic>>.from(value);
    try {
      return (jsonDecode(value as String) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
