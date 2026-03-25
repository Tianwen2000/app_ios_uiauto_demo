import 'package:flutter_driver/flutter_driver.dart';

import '../support/case_runner.dart';

class DiscoverPage {
  static SerializableFinder get searchField => find.byType('TextField');
  static SerializableFinder get addToBagButton => find.text('Add to bag');
  static SerializableFinder get audioFilterChip => find.ancestor(
    of: find.text('Audio'),
    matching: find.byType('FilterChip'),
  );

  static Future<void> waitForCatalog(CaseRunner runner) async {
    await runner.waitForText('Studio Cart');
  }

  static Future<void> waitForWelcome(CaseRunner runner, String username) async {
    await runner.waitForText('Good to see you, $username');
  }

  static Future<void> search(
    CaseRunner runner, {
    required String stepId,
    required String stepName,
    required String query,
  }) async {
    await runner.enterTextViaTap(
      stepId: stepId,
      stepName: stepName,
      target: 'Search items or moods',
      finder: searchField,
      value: query,
    );
  }

  static Future<void> addFirstProductToBag(
    CaseRunner runner, {
    required String stepId,
    required String stepName,
  }) async {
    await runner.tapFinder(
      stepId: stepId,
      stepName: stepName,
      target: 'Add to bag',
      finder: addToBagButton,
    );
  }

  static Future<void> filterByAudio(
    CaseRunner runner, {
    required String stepId,
    required String stepName,
  }) async {
    await runner.tapFinder(
      stepId: stepId,
      stepName: stepName,
      target: 'Audio',
      finder: audioFilterChip,
    );
  }
}
