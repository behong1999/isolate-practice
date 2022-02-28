import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'dart:developer' as devtools show log;

extension Log on Object {
  void log() => devtools.log(toString());
}

void main() {
  runApp(const MyApp());
}

class Person {
  final String name;
  final int age;

  Person({
    required this.name,
    required this.age,
  });

  Person.fromJson(Map<String, dynamic> json)
      : name = json["name"],
        age = json["age"];
}

//* ENTRANCE
Future<Iterable<Person>> getPeople() async {
  final rp =
      ReceivePort(); //* ReceivePort is READ/WRITE tunnel to grab values from isolates main function. Whereas, SendPort is WRITE only
  await Isolate.spawn(_getPeople,
      rp.sendPort); //*creates and starts the isolate for the background people.
  return await rp
      .first; //* Await the first result from the ReceivePort Stream and quit
}

//* Spawned Isolate
void _getPeople(SendPort sp) async {
  const url = "http://192.168.96.119:58051/apis/data.json";
  final people = await HttpClient()
      .getUrl(Uri.parse(url))
      .then((req) => req.close())
      .then((response) => response.transform(utf8.decoder).join())
      .then((jsonString) => json.decode(jsonString) as List<dynamic>)
      .then((list) => list.map((json) => Person.fromJson(json)));

  //
  //* The memory that holds the message in the exiting isolate isn’t copied,
  //* but instead is transferred to the receiving isolate.
  //* That transfer is quick and completes in constant time — O(1).
  //
  Isolate.exit(sp, people);
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'ISOLATES'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Page')),
      body: TextButton(
        onPressed: () async {
          final people = await getPeople();
          people.log();
          // log(people as String);
        },
        child: Text('Press it'),
      ),
    );
  }
}
