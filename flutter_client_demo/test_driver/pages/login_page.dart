import 'package:flutter_driver/flutter_driver.dart';

import '../support/case_runner.dart';

class LoginPage {
  static SerializableFinder get usernameField => find.ancestor(
    of: find.text('Username'),
    matching: find.byType('TextField'),
  );

  static SerializableFinder get passwordField => find.ancestor(
    of: find.text('Password'),
    matching: find.byType('TextField'),
  );

  static SerializableFinder get startShoppingButton =>
      find.text('Start shopping');

  static Future<void> waitForVisible(CaseRunner runner) async {
    await runner.waitForText('Start shopping');
    await runner.waitForText('Username');
    await runner.waitForText('Password');
  }

  static Future<void> login(
    CaseRunner runner, {
    required String stepId,
    required String stepName,
    required String username,
    required String password,
  }) async {
    await runner.enterTextViaTap(
      stepId: stepId,
      stepName: stepName,
      target: 'Username',
      finder: usernameField,
      value: username,
    );
    await runner.enterTextViaTap(
      stepId: stepId,
      stepName: stepName,
      target: 'Password',
      finder: passwordField,
      value: password,
      redact: true,
    );
    await runner.tapFinder(
      stepId: stepId,
      stepName: stepName,
      target: 'Start shopping',
      finder: startShoppingButton,
    );
  }
}
