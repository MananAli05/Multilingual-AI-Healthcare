import 'package:flutter/material.dart';

class MedicalRecordsScreen extends StatelessWidget {
  const MedicalRecordsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Records'),
      ),
      body: const Center(
        child: Text(
          'Medical Records Screen - Coming Soon',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}