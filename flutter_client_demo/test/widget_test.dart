import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_client_demo/app.dart';

void main() {
  Future<void> loginAsDemoUser(WidgetTester tester) async {
    await tester.pumpWidget(const ClientDemoApp());

    await tester.enterText(find.byType(TextField).at(0), 'operator');
    await tester.enterText(find.byType(TextField).at(1), '123456');

    final loginButton = find.widgetWithText(FilledButton, 'Start shopping');
    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
    await tester.pumpAndSettle();
  }

  testWidgets('login enters the discover page', (WidgetTester tester) async {
    await loginAsDemoUser(tester);

    expect(find.textContaining('Good to see you, operator'), findsOneWidget);
    expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);
  });

  testWidgets('catalog interactions update favorites and cart count', (
    WidgetTester tester,
  ) async {
    await loginAsDemoUser(tester);

    await tester.tap(find.byIcon(Icons.favorite_border).first);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Add to bag').first);
    await tester.pumpAndSettle();

    expect(find.text('1'), findsWidgets);

    await tester.enterText(find.byType(TextField).first, 'Wave');
    await tester.pumpAndSettle();

    expect(find.text('Wave Headset'), findsOneWidget);
    expect(find.text('Focus Lamp'), findsNothing);
  });

  testWidgets('profile toggles and logout work', (WidgetTester tester) async {
    await loginAsDemoUser(tester);

    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    final budgetSlider = find.byType(Slider);
    await tester.ensureVisible(budgetSlider);
    await tester.drag(budgetSlider, const Offset(200, 0));
    await tester.pumpAndSettle();

    expect(find.textContaining(r'$'), findsWidgets);

    final logoutButton = find.widgetWithText(FilledButton, 'Sign out');
    await tester.ensureVisible(logoutButton);
    await tester.tap(logoutButton);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Start shopping'), findsOneWidget);
  });
}
