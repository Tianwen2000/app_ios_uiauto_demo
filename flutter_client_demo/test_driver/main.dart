import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';

import 'cases/search_category_filters_case.dart';
import 'cases/smoke_login_browse_logout_case.dart';
import 'support/case_runner.dart';
import 'support/driver_factory.dart';

const String _defaultRunId = 'flutter_driver_local';
const String _defaultUsername = 'operator';
const String _defaultPassword = '123456';

Future<void> main() async {
  final String runId = Platform.environment['QA_RUN_ID'] ?? _defaultRunId;
  final String reportsDir =
      Platform.environment['QA_ARTIFACTS_DIR'] ??
      Platform.environment['QA_REPORTS_DIR'] ??
      Directory.current.path;
  final String testName =
      Platform.environment['QA_TEST_CASE'] ??
      'testSmoke_LoginBrowseProfileLogout';
  final String username =
      Platform.environment['QA_TEST_USERNAME'] ?? _defaultUsername;
  final String password =
      Platform.environment['QA_TEST_PASSWORD'] ?? _defaultPassword;

  final FlutterDriver driver = await connectDriverWithRetry();
  final CaseRunner runner = CaseRunner(
    driver: driver,
    runId: runId,
    reportsRoot: Directory(reportsDir),
    testName: testName,
  );

  try {
    await driver.setTextEntryEmulation(enabled: true);

    switch (testName) {
      case 'testSmoke_LoginBrowseProfileLogout':
        await runner.run(
          () => runSmokeLoginBrowseLogoutCase(
            runner,
            username: username,
            password: password,
          ),
        );
        break;
      case 'testSearchAndCategoryFilters':
        await runner.run(
          () => runSearchCategoryFiltersCase(runner, password: password),
        );
        break;
      default:
        throw StateError('Unknown QA_TEST_CASE: $testName');
    }
  } finally {
    await driver.close();
  }
}
