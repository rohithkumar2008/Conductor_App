
import 'package:flutter_test/flutter_test.dart';
import 'package:conductor_app/main.dart';
import 'package:conductor_app/pages/home_page.dart';
import 'package:conductor_app/widgets/lively_bottom_nav_bar.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('App smoke test - verifies MyApp launches', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Home page smoke test - verifies LivelyBottomNavBar presence', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(LivelyBottomNavBar), findsOneWidget);
  });
}

