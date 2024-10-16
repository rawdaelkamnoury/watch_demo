import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'WhistleBox HR Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});


  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _heartRate = 0;
  final MethodChannel channel = const MethodChannel('com.example.watchApp');
  Future<void> sendDataToNative() async {
    // Send data to Native
    await channel.invokeMethod(
        "flutterToWatch", {"method": "sendHRToNative", "data": _heartRate});
  }

  Future<void> _initFlutterChannel() async {
    channel.setMethodCallHandler((call) async {
      // Receive data from Native
      switch (call.method) {
        case "sendHRToFlutter":
          _heartRate = call.arguments["data"]["counter"];
          sendDataToNative();
          break;
        default:
          break;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _initFlutterChannel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF27C0C1),
        title: Text(widget.title,style: TextStyle(
            color: Colors.white
        )),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Image.asset("assets/logo.png",height: 50),
            SizedBox(height: 100,),



            Text(
              '$_heartRate BPM',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold
              ),
            ),
            SizedBox(height: 50,),
            Text(
              'Personalize Your Mental Health State',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
//
//  testWatchApp.swift
//  testWatch Watch App
//
//  Created by megamind fatma on 16/10/2024.
//

// import SwiftUI
//
// @main
// struct testWatch_Watch_AppApp: App {
// var body: some Scene {
// WindowGroup {
// ContentView()
// }
// }
// }
