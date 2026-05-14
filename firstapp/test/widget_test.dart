// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:MediCare/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Since main() initializes Firebase/Supabase, we use the root widget directly.
    await tester.pumpWidget(const MedicalApp());

    // Basic check to see if the splash or home screen starts up.
    // Note: Since you have a splash screen and initializations, 
    // real widget tests would need mock initializations.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
