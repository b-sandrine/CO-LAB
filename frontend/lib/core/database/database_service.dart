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
      version: 1,
      onCreate: _create,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
    );
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
