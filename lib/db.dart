import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

_database_func() async {
  return openDatabase(
    join(await getDatabasesPath(), 'information.db'),
    onCreate: (db, version) {
      return db.execute(
        'CREATE TABLE info(id INTEGER PRIMARY KEY, domain TEXT, name TEXT, key TEXT)',
      );
    },
    version: 1,
  );
}

final database = _database_func();