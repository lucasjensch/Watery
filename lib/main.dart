import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

void main() {
  runApp(WaterTrackerApp());
}

class WaterTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Watery',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: WaterTracker(),
    );
  }
}

class WaterTracker extends StatefulWidget {
  @override
  _WaterTrackerState createState() => _WaterTrackerState();
}

class _WaterTrackerState extends State<WaterTracker> {
  double totalWater = 2000; // Standardmenge in ml
  double consumedWater = 0;
  String lastUpdateDate = "";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      totalWater = prefs.getDouble('totalWater') ?? 2000;
      consumedWater = prefs.getDouble('consumedWater') ?? 0;
      lastUpdateDate = prefs.getString('lastUpdateDate') ?? _getToday();
    });

    // Prüfen, ob der Fortschritt zurückgesetzt werden muss
    if (lastUpdateDate != _getToday()) {
      _resetDailyProgress();
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('totalWater', totalWater);
    await prefs.setDouble('consumedWater', consumedWater);
    await prefs.setString('lastUpdateDate', _getToday());
  }

  void _resetDailyProgress() {
    setState(() {
      consumedWater = 0;
      lastUpdateDate = _getToday();
    });
    _saveData();
  }

  String _getToday() {
    final now = DateTime.now();
    return "${now.year}-${now.month}-${now.day}";
  }

  void drinkWater() {
    if (consumedWater + 250 <= totalWater) {
      setState(() {
        consumedWater += 250;
      });
      _saveData();
    }
  }

  void resetSettings() async {
    final newTotal = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => SettingsPage(totalWater: totalWater)),
    );
    if (newTotal != null) {
      setState(() {
        totalWater = newTotal;
        consumedWater = 0; // Fortschritt zurücksetzen
      });
      _saveData();
    }
  }

  @override
  Widget build(BuildContext context) {
    double progress = (consumedWater / totalWater).clamp(0, 1);
    return Scaffold(
      backgroundColor: Colors.orange.shade300,
      appBar: AppBar(
        backgroundColor: Colors.orange.shade900,
        title: Text(
          'Watery',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 35,
              color: Colors.grey.shade100),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: resetSettings,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Dein tägliches Ziel: ${(totalWater / 1000).toStringAsFixed(1)} Liter',
              style: TextStyle(
                fontSize: 25,
                color: Colors.grey.shade100,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 20),
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  width: 150,
                  height: 300,
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 8),
                      borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(50),
                          bottomRight: Radius.circular(50))),
                ),
                Container(
                  width: 150,
                  height: 300 * progress,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    border: Border.all(width: 8.0, color: Colors.white),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(50),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: drinkWater,
              child: Text(
                'Ein Glas getrunken (+250 ml)',
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Getrunken: ${(consumedWater / 1000).toStringAsFixed(1)} Liter',
              style: TextStyle(fontSize: 20, color: Colors.grey.shade100),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  final double totalWater;

  SettingsPage({required this.totalWater});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
        text: (widget.totalWater / 1000).toStringAsFixed(1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Einstellungen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tägliches Ziel in Litern:',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'z.B. 2.5',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final newTotal = double.tryParse(_controller.text);
                if (newTotal != null && newTotal > 0) {
                  Navigator.pop(
                      context, newTotal * 1000); // Liter in ml umrechnen
                }
              },
              child: Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }
}
