// database/database_helper.dart

import 'package:attheblocks/detail_form_page/model/offline_submission_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  late Database _database;

  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    _database = await _initDatabase();
    return _database;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'offline_forms.db');
    return await openDatabase(path, version: 1, onCreate: _createDatabase);
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute(
        'CREATE TABLE Submissions (id INTEGER PRIMARY KEY, date TEXT, itemId TEXT, formDataList TEXT)');
  }

  Future<int> insertSubmission(SubmissionModel submission) async {
    Database db = await instance.database;
    return await db.insert('Submissions', submission.toMap());
  }

  Future<List<SubmissionModel>> retrieveSubmissions() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('Submissions');
    return List.generate(maps.length, (i) {
      return SubmissionModel.fromMap(maps[i]);
    });
  }

  Future<int> deleteAllSubmissions() async {
    Database db = await instance.database;
    return await db.delete('Submissions');
  }

  Future<int> deleteSubmission(String id) async {
    Database db = await _initDatabase();
    return await db.delete('Submissions', where: 'itemId = ?', whereArgs: [id]);
  }
}
