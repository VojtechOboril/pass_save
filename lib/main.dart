import 'package:flutter/material.dart';
//import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:math';
import 'db.dart' as db;

List<Info> saved = <Info>[];
final storage = new FlutterSecureStorage();


void main() {
  runApp(MaterialApp(
    title: 'Password saver',
    home: Home(),
  ));
}

String _randomValue() {
  final rand = Random();
  final codeUnits = List.generate(20, (index) {
    return rand.nextInt(26) + 65;
  });

  return String.fromCharCodes(codeUnits);
}

Future<void> insertInfo(Info info) async {
  final database = await db.database;

  await database.insert(
    'info',
    info.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<List<Info>> getInfo() async {
  final database = await db.database;
  final List<Map<String, dynamic>> maps = await database.query('info');

  return List.generate(maps.length, (i) {
    return Info(
      maps[i]['domain'],
      maps[i]['name'],
      maps[i]['key'],
    );
  });
}

class Info {
  String domain;
  String name;
  String key;

  Info(this.domain, this.name, this.key);

  Map<String, String> toMap() {
    return {
      "domain": domain,
      "name": name,
      "key": key,
    };
  }
}

class InfoRow extends StatelessWidget {
  final Info info;

  InfoRow(this.info);
  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () async {
        String? password;
        password = await storage.read(key: info.key);
        Navigator.push( context,
        MaterialPageRoute(builder: (context) => ShowData(info, password ?? "")),
        );
      },
      child: Row(
        children: <Widget>[
          Expanded(child: Text(info.domain)),
          Expanded(child: Text(info.name)),
        ],
      )
    );
  }
}

class Home extends StatefulWidget {
  _Home createState() => _Home();
}

class _Home extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Password saver'),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  child: Text('Add new'),
                  onPressed: () async {
                    final newData = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddNewPassword()),
                    );
                    if (newData != null) {
                      insertInfo(newData);
                      saved = await getInfo();
                      setState(() {});
                    }
                  },
                ),
                ElevatedButton(
                  child: Text('Reload'),
                  onPressed: () async {
                    saved = await getInfo();
                    setState(() {});
                  },
                ),
              ],
            ),
            for (Info item in saved) InfoRow(item)
          ],
        )
      ),
    );
  }
}

class AddNewPassword extends StatefulWidget {
  _AddNewPassword createState() => _AddNewPassword();
}

class _AddNewPassword extends State<AddNewPassword> {

  bool _visible = false;

  final _domainController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();


  @override
  Widget build(BuildContext context) {
    void _changeVisibility() {
      setState(() {
        _visible = !_visible;
      });
    }

    void _saveData(){
      var data;
      if (_domainController.text != "" && _nameController.text != "" && _passwordController.text != "") {
        String value = _randomValue();
        storage.write(key: value, value: _passwordController.text);
        data = Info(_domainController.text, _nameController.text, value);
        Navigator.pop(context, data);
      }
      else {
        showDialog<String>(
          builder: (BuildContext context) => AlertDialog(
            content: const Text("You must fill all information."),
          ),
          context: context,
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Add new password"),
      ),
      body: Center(
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _domainController,
                decoration: const InputDecoration(
                  hintText: "Domain",
                ),
              ),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: "Name",
                ),
              ),

              Row(
                children: <Widget>[
                  Expanded(
                    flex: 5,
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: !_visible,
                      decoration: const InputDecoration(
                        hintText: "Password",
                      ),
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      icon: Icon(_visible? Icons.visibility : Icons.visibility_off),
                      onPressed: _changeVisibility,
                    ),
                  )
                ],
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ElevatedButton(
                    child: Text("Back"),
                    onPressed: () {Navigator.pop(context, null);},
                  ),
                  ElevatedButton(
                    child: Text("Save"),
                    onPressed: _saveData,
                  ),
                ],
              )
            ],
          )
      ),
    );
  }
}

class ShowData extends StatefulWidget {
  Info info;
  String password;
  ShowData(this.info, this.password);
  _ShowData createState() => _ShowData(info, password);
}

class _ShowData extends State<ShowData> {
  Info info;
  String password;
  _ShowData(this.info, this.password);
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your information'),
      ),
      body: Column(
        children: <Widget>[
          Row(
              children: <Widget>[
                Expanded(child: const Text("Domain: "), flex: 1),
                Expanded(child: SelectableText(info.domain), flex: 2),
              ]
          ),
          Row(
              children: <Widget>[
                Expanded(child: const Text("Name: "), flex: 1),
                Expanded(child: SelectableText(info.name), flex: 2),
              ]
          ),
          Row(
              children: <Widget>[
                Expanded(child: const Text("Password: "), flex: 2),
                Expanded(
                  child: SelectableText(
                    _visible == true
                        ? password
                        : '${password.replaceAll(RegExp(r"."), "*")}'
                  ),
                  flex: 3
                ),
                Expanded(
                  child: IconButton(
                    icon: Icon(_visible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {setState(() {
                      _visible = !_visible;
                      });
                    },
                  ),
                  flex: 1,
                )
              ]
          ),
        ],
      ),
    );
  }
}