import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class LifeDatabase {
  LifeDatabase._();
  static final instance=LifeDatabase._();
  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final desktop=Platform.isWindows||Platform.isLinux||Platform.isMacOS;
    if(desktop) sqfliteFfiInit();
    final factory=desktop?databaseFactoryFfi:databaseFactory;
    final dir=await getApplicationDocumentsDirectory();
    final path=p.join(dir.path,'life_os','life_os.db');
    await Directory(p.dirname(path)).create(recursive:true);
    return factory.openDatabase(path,options:OpenDatabaseOptions(
      version:1,
      onConfigure:(db)=>db.execute('PRAGMA foreign_keys = ON'),
      onCreate:(db,_) async {
        await db.execute('CREATE TABLE tasks(id INTEGER PRIMARY KEY,title TEXT NOT NULL,description TEXT NOT NULL DEFAULT "",due_at INTEGER,priority TEXT NOT NULL,category TEXT NOT NULL,project_id INTEGER,reminder_at INTEGER,completed INTEGER NOT NULL DEFAULT 0,created_at INTEGER NOT NULL)');
        await db.execute('CREATE INDEX idx_tasks_due ON tasks(due_at)');
        await db.execute('CREATE INDEX idx_tasks_status ON tasks(completed)');
        await db.execute('CREATE TABLE goals(id INTEGER PRIMARY KEY,name TEXT NOT NULL,category TEXT NOT NULL,deadline INTEGER,progress INTEGER NOT NULL DEFAULT 0,created_at INTEGER NOT NULL)');
        await db.execute('CREATE TABLE habits(id INTEGER PRIMARY KEY,name TEXT NOT NULL,icon TEXT NOT NULL,frequency TEXT NOT NULL,completed_days TEXT NOT NULL DEFAULT "[]",created_at INTEGER NOT NULL)');
        await db.execute('CREATE TABLE projects(id INTEGER PRIMARY KEY,name TEXT NOT NULL,description TEXT NOT NULL DEFAULT "",status TEXT NOT NULL,progress INTEGER NOT NULL DEFAULT 0,created_at INTEGER NOT NULL)');
        await db.execute('CREATE TABLE notes(id INTEGER PRIMARY KEY,title TEXT NOT NULL,body TEXT NOT NULL,tags TEXT NOT NULL DEFAULT "",updated_at INTEGER NOT NULL)');
        await db.execute('CREATE TABLE ideas(id INTEGER PRIMARY KEY,title TEXT NOT NULL,description TEXT NOT NULL DEFAULT "",status TEXT NOT NULL,created_at INTEGER NOT NULL)');
      },
    ));
  }

  Future<int> nextId(String table) async {
    final rows=await (await database).rawQuery('SELECT COALESCE(MAX(id),0)+1 AS next_id FROM $table');
    return Sqflite.firstIntValue(rows)??1;
  }
  Future<List<Map<String,Object?>>> all(String table,{String? orderBy}) async => (await database).query(table,orderBy:orderBy);
  Future<void> save(String table,Map<String,Object?> row) async => (await database).insert(table,row,conflictAlgorithm:ConflictAlgorithm.replace);
  Future<void> delete(String table,int id) async => (await database).delete(table,where:'id=?',whereArgs:[id]);
  Future<void> clearAll() async {
    final db=await database;
    await db.transaction((tx) async { for(final t in ['tasks','goals','habits','projects','notes','ideas']) { await tx.delete(t); }});
  }
}
