import 'package:flutter_driver/flutter_driver.dart';

import '../support/case_runner.dart';

class ProfilePage {
  static SerializableFinder get releaseNotificationsTile =>
      find.text('Release notifications');
  static SerializableFinder get expressCheckoutTile =>
      find.text('Express checkout');
  static SerializableFinder get signOutButton => find.text('Sign out');

  static Future<void> waitForVisible(CaseRunner runner) async {
    await runner.waitForText('Release notifications');
  }

  static Future<void> waitForUsername(
    CaseRunner runner,
    String username,
  ) async {
    await runner.waitForText(username);
  }

  static Future<void> toggleReleaseNotifications(
    CaseRunner runner, {
    required String stepId,
    required String stepName,
  }) async {
    await runner.tapFinder(
      stepId: stepId,
      stepName: stepName,
      target: 'Release notifications',
      finder: releaseNotificationsTile,
    );
  }

  static Future<void> toggleExpressCheckout(
    CaseRunner runner, {
    required String stepId,
    required String stepName,
  }) async {
    await runner.tapFinder(
      stepId: stepId,
      stepName: stepName,
      target: 'Express checkout',
      finder: expressCheckoutTile,
    );
  }

  static Future<void> signOut(
    CaseRunner runner, {
    required String stepId,
    required String stepName,
  }) async {
    await runner.tapFinder(
      stepId: stepId,
      stepName: stepName,
      target: 'Sign out',
      finder: signOutButton,
    );
  }
}
