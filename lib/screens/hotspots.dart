import 'package:flutter/material.dart';

class HotspotsScreen extends StatelessWidget {
  const HotspotsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fishing Spots'),
        backgroundColor: const Color(0xFF151d67), // Match the theme
      ),
      body: Center(
        child: const Text(
          'Fishing Spots Screen',
          style: TextStyle(fontSize: 24, color: Colors.black),
        ),
      ),
    );
  }
}
