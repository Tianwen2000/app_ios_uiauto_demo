import 'package:flutter_driver/flutter_driver.dart';

import '../support/case_runner.dart';

class ShellPage {
  static SerializableFinder get accountTab => find.text('Account');
  static SerializableFinder get shopTab => find.text('Shop');

  static Future<void> openAccount(
    CaseRunner runner, {
    required String stepId,
    required String stepName,
  }) async {
    await runner.tapFinder(
      stepId: stepId,
      stepName: stepName,
      target: 'Account',
      finder: accountTab,
    );
  }

  static Future<void> openShop(
    CaseRunner runner, {
    required String stepId,
    required String stepName,
  }) async {
    await runner.tapFinder(
      stepId: stepId,
      stepName: stepName,
      target: 'Shop',
      finder: shopTab,
    );
  }
}
